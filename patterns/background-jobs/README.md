# Background Jobs Patterns
> See [pattern-lifecycle.md](../../core/pattern-lifecycle.md) for scoring.

## Overview

Patterns for reliable asynchronous work execution. Use these whenever a task must happen outside the request-response cycle: sending emails, processing uploads, syncing external systems, or running scheduled reports. The patterns here address the core failure modes of job queues: lost jobs, duplicate execution, cascading retry storms, and failed jobs that disappear silently.

---

## Pattern: Job Queue with Retry & Backoff

**Problem:** Jobs that fail due to transient errors (network blips, downstream API rate limits) are either lost or retried immediately in a tight loop that worsens the downstream problem.

**Solution:** Enqueue jobs in a durable queue (Redis-backed BullMQ, Celery, or Temporal). On failure, retry with exponential backoff up to a configured maximum. After all retries are exhausted, move the job to a Dead Letter Queue rather than discarding it.

**Implementation Notes:**
- Add jitter to the backoff delay (multiply by a small random factor) to prevent retry storms when many jobs fail simultaneously.
- Set a `maxRetries` ceiling — infinite retries mask bugs that will never self-heal.
- Log each retry attempt with the attempt number, delay, and error; this is the primary debugging signal.
- Include a `jobId` in all log lines and traces so a job's full lifecycle is reconstructable.

**Example:**
```typescript
import { Queue, Worker, QueueEvents } from 'bullmq';
import { connection } from './redis';

export const emailQueue = new Queue('email', {
  connection,
  defaultJobOptions: {
    attempts: 5,
    backoff: {
      type: 'exponential',
      delay: 1_000, // 1s, 2s, 4s, 8s, 16s (+jitter applied by BullMQ)
    },
    removeOnComplete: { count: 500 },
    removeOnFail: false, // keep failed jobs for DLQ inspection
  },
});

export const emailWorker = new Worker(
  'email',
  async (job) => {
    const { to, subject, templateId, data } = job.data;
    await mailer.send({ to, subject, templateId, data });
  },
  {
    connection,
    concurrency: 10,
  }
);

emailWorker.on('failed', (job, err) => {
  console.error({
    event: 'job.failed',
    job_id: job?.id,
    attempt: job?.attemptsMade,
    queue: 'email',
    error: err.message,
  });
});
```

**Common Mistakes:**
- Using a fixed retry delay — the queue hammers a rate-limited API at the same interval indefinitely.
- Not setting `removeOnFail: false` — failed jobs are discarded, making post-mortem analysis impossible.
- Catching all errors inside the job handler and returning success — the queue never sees the failure and stops retrying.

**Security Considerations:**
- Do not store sensitive data (passwords, tokens) in job payloads; store an ID and look up the value at execution time.
- Validate job data at the start of the worker handler — enqueued payloads may be malformed or tampered with if the queue is shared.

**Testing:**
Mock the mailer and assert that a thrown error triggers a retry with an increasing delay. Assert that after `maxRetries` the job lands in the failed set (DLQ). Assert that a successful execution removes the job from the active set.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Scheduled Jobs / Cron

**Problem:** Cron tasks running on multiple instances of a service execute concurrently, causing duplicate runs — double billing, duplicate emails, or conflicting writes.

**Solution:** Make every cron task idempotent, then guard against concurrent runs with a distributed lock (Redis `SET NX PX`). The lock TTL must exceed the maximum expected job duration; if the job finishes early, release the lock explicitly.

**Implementation Notes:**
- Treat every cron handler as if it could be invoked twice simultaneously — the outcome must be the same either way.
- Set the lock TTL to 2× the expected maximum runtime; if the job can take 5 min, set TTL to 10 min.
- Log a clear `skipped` event when a lock is not acquired — this is not an error, but it is useful signal.
- Clock skew between nodes can cause two instances to believe the schedule fired at different times; build idempotency into the task logic, not just the lock.

**Example:**
```typescript
import { Queue } from 'bullmq';
import { createClient } from 'redis';

const redis = createClient({ url: process.env.REDIS_URL });
const LOCK_TTL_MS = 10 * 60 * 1000; // 10 minutes

async function withDistributedLock(lockKey: string, fn: () => Promise<void>): Promise<void> {
  const lockValue = crypto.randomUUID();
  const acquired = await redis.set(lockKey, lockValue, { NX: true, PX: LOCK_TTL_MS });

  if (!acquired) {
    console.info({ event: 'cron.lock_skipped', lock_key: lockKey });
    return;
  }

  try {
    await fn();
  } finally {
    // Release only if we still own the lock (guards against TTL expiry during long runs)
    const current = await redis.get(lockKey);
    if (current === lockValue) await redis.del(lockKey);
  }
}

// BullMQ repeatable job (replaces cron daemon)
const reportQueue = new Queue('reports', { connection: redis });
await reportQueue.add(
  'daily-summary',
  {},
  { repeat: { pattern: '0 6 * * *', tz: 'UTC' }, jobId: 'daily-summary' }
);

// Worker wraps the task in the distributed lock
const worker = new Worker('reports', async (job) => {
  await withDistributedLock(`lock:${job.name}`, async () => {
    await generateDailySummary();
  });
}, { connection: redis });
```

**Common Mistakes:**
- Running cron jobs from a system cron daemon on every server — all instances fire simultaneously.
- Setting the lock TTL shorter than the job duration — the lock expires mid-run and a second instance starts.
- Not releasing the lock on success — blocks the next scheduled run until TTL expires.

**Security Considerations:**
- Restrict which services can enqueue or trigger scheduled jobs; treat the cron trigger as a privileged operation.
- Log all cron executions with duration and outcome; unexpected skips can indicate a stuck previous run.

**Testing:**
Spin up two worker instances in a test and assert that only one executes the handler when both attempt to acquire the lock simultaneously. Assert the second logs a `cron.lock_skipped` event. Assert the lock is released after a successful run.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Idempotent Workers

**Problem:** At-least-once delivery guarantees mean a worker may receive the same job multiple times (network retries, broker restarts). Processing it twice causes duplicate side effects: double charges, duplicate emails, or duplicate DB rows.

**Solution:** Assign every job an idempotency key before enqueueing. The worker checks this key against a deduplication store (DB or Redis) before processing. If the key is already recorded as completed, the worker returns success without re-executing.

**Implementation Notes:**
- Generate the idempotency key from deterministic inputs (e.g., `sha256(userId + orderId + "charge")`), not from a random UUID, so re-enqueuing the same logical operation produces the same key.
- Store the key with a TTL long enough to cover the maximum retry window plus a safety margin.
- Record the key as `processing` before starting work and `complete` after committing; this handles crashes mid-execution.
- The deduplication check and the business-logic commit should be in the same DB transaction where possible.

**Example:**
```typescript
import crypto from 'crypto';
import { db } from './db';

function makeIdempotencyKey(namespace: string, ...parts: string[]): string {
  return crypto.createHash('sha256').update([namespace, ...parts].join(':')).digest('hex');
}

async function processChargeJob(job: { data: { userId: string; orderId: string; amountCents: number } }) {
  const { userId, orderId, amountCents } = job.data;
  const key = makeIdempotencyKey('charge', userId, orderId);

  await db.transaction(async (trx) => {
    const existing = await trx('idempotency_keys').where({ key }).first();
    if (existing?.status === 'complete') {
      console.info({ event: 'job.deduplicated', key, order_id: orderId });
      return; // safe to return — already processed
    }

    await trx('idempotency_keys')
      .insert({ key, status: 'processing', created_at: new Date() })
      .onConflict('key').merge({ status: 'processing' });

    await chargePayment(userId, orderId, amountCents); // external side effect

    await trx('idempotency_keys').where({ key }).update({ status: 'complete' });
  });
}
```

**Common Mistakes:**
- Using a random UUID as the idempotency key — re-enqueuing the same logical job generates a new key and processes twice.
- Checking the key but committing it outside the transaction — a crash between the check and the commit allows a double-execution.
- Keeping keys forever — unbounded growth; set a TTL or a periodic cleanup job.

**Security Considerations:**
- The idempotency key table can be probed to infer which operations have occurred; restrict read access to the service's own role.
- Validate that the job data matches what was originally processed for a given key if replay attacks are a concern.

**Testing:**
Enqueue the same job twice with identical inputs and assert the business-logic side effect (e.g., payment charge) runs exactly once. Assert the second execution logs a `job.deduplicated` event. Assert behavior is correct when the first execution crashes mid-transaction.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Dead Letter Queue (DLQ)

**Problem:** Jobs that exhaust all retries are silently discarded, leaving no record of what failed or any mechanism to reprocess once the root cause is fixed.

**Solution:** Route exhausted jobs to a dedicated Dead Letter Queue. Attach the final error, stack trace, and original payload. Provide a monitored interface for inspection and selective requeueing after the underlying issue is resolved.

**Implementation Notes:**
- Alert when the DLQ depth crosses a threshold — a growing DLQ is a leading indicator of a systemic failure.
- Store the failure reason and all retry attempts alongside the job so diagnosis does not require log searching.
- Requeueing from the DLQ must be a deliberate, human-initiated action — never auto-requeue without human review; the same bug may trigger the same failure loop.
- Implement a requeue endpoint or script that moves the job back to the head of the processing queue with a reset attempt counter.

**Example:**
```typescript
import { Queue, Worker, UnrecoverableError } from 'bullmq';
import { connection } from './redis';

// Jobs moved to failed set in BullMQ serve as the DLQ when removeOnFail is false.
// Use a dedicated DLQ queue for explicit routing and monitoring.
const dlq = new Queue('email:dlq', { connection });

const emailWorker = new Worker('email', async (job) => {
  const { to, templateId } = job.data;

  if (!to || !templateId) {
    // Throw UnrecoverableError to skip retries and go straight to DLQ
    throw new UnrecoverableError(`Invalid job payload: missing to or templateId`);
  }

  await mailer.send(job.data);
}, { connection });

emailWorker.on('failed', async (job, err) => {
  if (!job || job.attemptsMade < (job.opts.attempts ?? 1)) return; // still retrying

  // Exhausted — move to DLQ with metadata
  await dlq.add('failed-email', {
    originalJob: job.data,
    error: err.message,
    stack: err.stack,
    failedAt: new Date().toISOString(),
    attempts: job.attemptsMade,
  });

  console.error({ event: 'job.dlq', job_id: job.id, queue: 'email', error: err.message });
});

// Requeue script (run manually after fixing the root cause)
async function requeueFromDlq(dlqJobId: string) {
  const dlqJob = await dlq.getJob(dlqJobId);
  if (!dlqJob) throw new Error(`DLQ job ${dlqJobId} not found`);
  await emailQueue.add('retry-from-dlq', dlqJob.data.originalJob);
  await dlqJob.remove();
}
```

**Common Mistakes:**
- Auto-requeueing DLQ jobs on a timer — replays the failure loop without fixing the root cause.
- Not alerting on DLQ growth — failures accumulate unnoticed until a customer reports a problem.
- Discarding the original payload in the DLQ entry — makes it impossible to reprocess without re-triggering the upstream event.

**Security Considerations:**
- DLQ payloads contain the original job data, which may include PII; apply the same access controls as the main queue.
- Audit log every manual requeue action — requeueing is a privileged operation that can trigger real side effects.

**Testing:**
Configure a job to fail on every attempt. Assert it appears in the DLQ with the correct error message and original payload after all retries are exhausted. Assert that calling `requeueFromDlq` moves it back to the processing queue and removes it from the DLQ.

**Score:** TBD (see pattern-lifecycle.md)

## Official References
- [BullMQ Docs](https://docs.bullmq.io) — Redis-based job queue for Node.js
- [Celery Docs](https://docs.celeryq.dev) — Python distributed task queue
- [Temporal Docs](https://docs.temporal.io) — durable workflow execution engine
- [Sidekiq Docs](https://github.com/sidekiq/sidekiq/wiki) — Ruby background job processing
