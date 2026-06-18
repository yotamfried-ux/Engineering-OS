# Deployment Patterns
> See [pattern-lifecycle.md](../../core/pattern-lifecycle.md) for scoring.

## Overview
Apply these patterns when planning how a change moves from a passing CI build into production. Choose the pattern based on risk tolerance and rollback speed requirements: blue-green for instant rollback, canary for metric-gated confidence, feature flags for decoupling deploy from release, and expand-contract for schema changes that must stay backward-compatible.

---

## Pattern: Blue-Green Deployment

**Problem:** Deploying directly to production creates downtime and makes rollback slow and risky if the new version has a defect.

**Solution:** Maintain two identical production environments (blue = live, green = idle). Deploy the new version to green, run smoke tests, then switch all traffic to green instantly. Blue becomes the rollback target.

**Implementation Notes:**
- The traffic switch happens at the load balancer or DNS layer — not in application code.
- Both environments must point to the same database; schema changes must be backward-compatible before the switch (see Zero-Downtime Database Migration below).
- Smoke tests run against green while blue is still live — users are unaffected if green fails tests.
- Keep blue running for at least 30 minutes after the switch to allow fast rollback if metrics degrade.
- Decommission blue only after you are confident green is stable.

**Example:**
```typescript
// scripts/deploy-blue-green.ts
// Pseudocode — adapt to your cloud provider (AWS ALB, Cloudflare, Vercel, etc.)

async function deployBlueGreen(newImageTag: string) {
  const lb = new LoadBalancer(process.env.LB_ARN);

  // Step 1: Deploy to idle (green) environment
  await greenEnv.deploy(newImageTag);
  await greenEnv.waitUntilHealthy({ timeoutMs: 120_000 });

  // Step 2: Run smoke tests against green while blue is live
  const smokeResult = await runSmokeTests(greenEnv.url);
  if (!smokeResult.passed) {
    await greenEnv.rollback();
    throw new Error(`Smoke tests failed: ${smokeResult.summary}`);
  }

  // Step 3: Atomic traffic switch
  await lb.setTargetGroup(greenEnv.targetGroupArn);
  console.log("Traffic switched to green. Blue is on standby for rollback.");

  // Step 4: Monitor for 30 minutes before decommissioning blue
  await monitorErrorRate({ durationMs: 30 * 60 * 1000, threshold: 0.01 });
  await blueEnv.decommission();
}
```

**Common Mistakes:**
- Switching traffic before smoke tests complete — green may serve errors to real users.
- Running different database schema versions on blue and green simultaneously without backward compatibility.
- Decommissioning blue immediately after the switch — eliminates the rollback option.

**Security Considerations:**
- Green must be inaccessible to the public during deployment; restrict inbound traffic to internal IPs and the smoke-test runner only.
- Ensure TLS certificates and environment secrets are provisioned on green before the switch.

**Testing:**
Deploy a version with a deliberate smoke-test failure and verify the script rolls back to the original image. Verify the load balancer target group changes atomically by checking access logs during the switch.

---

## Pattern: Canary Release

**Problem:** Blue-green gives a binary switch — all traffic moves at once. For high-risk changes, you want to validate real production traffic on a small slice before full rollout.

**Solution:** Route a small percentage of traffic (e.g., 5%) to the new version, monitor key metrics (error rate, latency, business KPIs), and progressively increase the percentage until 100% — or roll back automatically if a metric degrades.

**Implementation Notes:**
- Define rollout gates before deploying: which metrics, which thresholds, and how long to hold each stage.
- Start with internal users or a low-risk segment (e.g., a single region) for the canary slice.
- Automate the rollback trigger: if error rate on canary exceeds N× baseline, revert without human intervention.
- Canary works best with feature-flag infrastructure or weighted routing at the load balancer/CDN.
- Log the canary percentage as a dimension in your metrics to make comparison easy.

**Example:**
```python
# deploy/canary.py
import time
from monitoring import get_error_rate
from load_balancer import set_canary_weight, rollback

STAGES = [5, 20, 50, 100]          # percent of traffic to canary
HOLD_MINUTES = 10                   # minutes to hold each stage
ERROR_RATE_THRESHOLD = 0.02         # 2% — roll back if exceeded

def deploy_canary(new_version: str):
    deploy_to_canary_fleet(new_version)

    for weight in STAGES:
        set_canary_weight(weight)
        print(f"Canary at {weight}% — monitoring for {HOLD_MINUTES}m")

        deadline = time.time() + HOLD_MINUTES * 60
        while time.time() < deadline:
            error_rate = get_error_rate(target="canary", window_minutes=5)
            if error_rate > ERROR_RATE_THRESHOLD:
                print(f"Error rate {error_rate:.2%} exceeded threshold — rolling back")
                rollback()
                raise RuntimeError("Canary aborted")
            time.sleep(30)

    print("Canary complete — 100% traffic on new version")
```

**Common Mistakes:**
- Choosing too-short hold windows — not enough traffic to surface low-frequency errors.
- Gating only on error rate and ignoring latency percentiles (p95/p99) and business metrics (conversion, revenue).
- Running canary without the ability to automatically roll back — requires a human to notice and act.

**Security Considerations:**
- Canary instances must have the same security posture as production — same WAF rules, secrets, and network policies.
- Ensure canary requests cannot bleed data between the canary and stable cohorts (e.g., session affinity when state is involved).

**Testing:**
Deploy a canary version that injects a 5% artificial error rate. Verify the monitoring script detects the breach and triggers rollback within two monitoring windows.

---

## Pattern: Feature Flags

**Problem:** Merging long-lived feature branches causes integration pain, and deploying a new feature to all users at once couples the deploy event to the release decision.

**Solution:** Ship code to production behind a runtime flag that can be toggled on or off without a deploy, enabling trunk-based development and controlled rollout to user segments.

**Implementation Notes:**
- Use a dedicated flag service (GrowthBook, LaunchDarkly, Unleash, or a simple Supabase table) rather than environment variables — env vars require a redeploy to change.
- Flags should target segments: internal users first, then a percentage of accounts, then all users.
- Set a kill-switch flag for every new integration with an external service — allows instant disable without code change.
- Clean up flags within one sprint of full rollout — flag debt accumulates fast and makes code hard to reason about.
- Never use flags to branch permanent differences; they are for rollout control, not permanent A/B variants.

**Example:**
```typescript
// lib/flags.ts — thin wrapper over your flag provider
import { GrowthBook } from "@growthbook/growthbook";

export async function isEnabled(
  flagKey: string,
  context: { userId?: string; email?: string }
): Promise<boolean> {
  const gb = new GrowthBook({
    apiHost: process.env.GROWTHBOOK_API_HOST,
    clientKey: process.env.GROWTHBOOK_CLIENT_KEY,
    attributes: context,
  });
  await gb.init({ timeout: 500 });
  return gb.isOn(flagKey);
}

// Usage in a route handler
export async function handleCheckout(req: Request) {
  const newFlow = await isEnabled("checkout-v2", { userId: req.user.id });

  if (newFlow) {
    return checkoutV2(req);
  }
  return checkoutV1(req);
}
```

**Common Mistakes:**
- Nesting flags inside flags — creates a combinatorial explosion of states that is impossible to test.
- Forgetting to remove a flag after full rollout — leaves dead code paths that confuse future developers.
- Using a flag to hide broken code in production — flags should control rollout of working code, not mask incomplete features.

**Security Considerations:**
- Flag evaluation should never expose flag configuration to the client; evaluate server-side and send only the result.
- Audit who has permission to toggle flags — toggling a flag in production is a production action and should require the same approval as a deploy.

**Testing:**
Write tests for both branches of every flag. Verify the default state (flag off) is safe. Add a flag-cleanup lint rule or CI check that fails when flags older than N days are still in the codebase.

---

## Pattern: Zero-Downtime Database Migration

**Problem:** Deploying a schema change (renaming a column, adding a NOT NULL constraint) at the same time as the application code that uses the new schema breaks in-flight requests from the old code version.

**Solution:** Use the expand-contract pattern: first expand the schema to support both old and new code simultaneously, then deploy the new application code, then contract the schema by removing the old structure.

**Implementation Notes:**
- Phase 1 — Expand: add the new column (nullable, with a default), add a backfill job, keep the old column. Both old and new code work.
- Phase 2 — Migrate: deploy the new application code that reads/writes the new column. Old code still writes the old column (dual-write or backfill keeps them in sync).
- Phase 3 — Contract: once all instances run the new code, drop the old column and add any NOT NULL constraints.
- Never add a NOT NULL column without a default in a single migration on a table with existing rows — this locks the table.
- Each phase is a separate deployment, not a single migration file.

**Example:**
```python
# migrations/001_expand_add_full_name.py  (Phase 1)
def upgrade():
    op.add_column("users", sa.Column("full_name", sa.String(200), nullable=True))
    # Backfill existing rows
    op.execute("""
        UPDATE users
        SET full_name = first_name || ' ' || last_name
        WHERE full_name IS NULL
    """)

# --- Deploy new application code here (Phase 2) ---
# App writes to full_name; old instances still write first_name/last_name.
# A trigger or dual-write keeps full_name in sync during rollout.

# migrations/002_contract_drop_old_columns.py  (Phase 3, after all instances updated)
def upgrade():
    op.alter_column("users", "full_name", nullable=False)
    op.drop_column("users", "first_name")
    op.drop_column("users", "last_name")
```

**Common Mistakes:**
- Combining all three phases into a single migration and deploying with the application — causes errors for in-flight requests using the old schema.
- Adding NOT NULL without a default on a large table — takes a full table lock and causes downtime.
- Skipping the backfill step — Phase 3 NOT NULL constraint fails on rows with NULL values.

**Security Considerations:**
- Migrations run with elevated DB privileges; review them in a PR with the same scrutiny as application code.
- Test migrations on a production-sized dataset in staging — what takes 10ms on a small table can take 10 minutes on a large one.

**Testing:**
Run the expand migration, then deploy old application code against the new schema and verify it still works. Then run the contract migration and verify new application code works. Confirm the contract migration fails fast if any null values remain in the target column before the NOT NULL constraint is applied.

## Official References
- [Docker Docs](https://docs.docker.com) — containerization documentation
- [Kubernetes Docs](https://kubernetes.io/docs/home/) — container orchestration
- [GitHub Actions Docs](https://docs.github.com/en/actions) — CI/CD workflows
- [Vercel Docs](https://vercel.com/docs) — frontend deployment platform
- [12-Factor App](https://12factor.net) — methodology for cloud-native application design
