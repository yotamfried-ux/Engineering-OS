# Storage Patterns

> Pattern library for file storage, CDN delivery, and asset processing. See [pattern-lifecycle.md](../../core/pattern-lifecycle.md) for scoring and lifecycle.

## Overview

Patterns for storing, delivering, and processing user-uploaded and system-generated files. Covers secure direct uploads to object storage, CDN-backed delivery for performance, multi-step processing pipelines, and cost-effective tiering for infrequently accessed data.

---

## Pattern: Pre-signed URL Upload

**Problem:** Routing file uploads through the application server wastes bandwidth, adds latency, and creates a bottleneck — especially for large files.

**Solution:** The client requests a pre-signed URL from the server. The server generates a short-lived signed URL scoped to a specific key. The client uploads directly to S3 (or R2/GCS) without the file touching the application server.

**Architecture:**
```
Client  →  POST /api/upload/presign { filename, contentType }
Server  →  validate auth + type + size intent
        →  generate presigned PUT URL (TTL 5min, specific S3 key)
        →  return { uploadUrl, fileKey }
Client  →  PUT <uploadUrl> (file bytes, Content-Type header)  →  S3
Client  →  POST /api/upload/confirm { fileKey }
Server  →  verify file exists in S3  →  create DB record
```

**Implementation Notes:**
- Generate the S3 key server-side (never trust the client): `uploads/{userId}/{uuid}.{ext}`.
- Scope the presigned URL to a specific key, content type, and max size (`Content-Length-Range` condition).
- Confirm step prevents clients from linking arbitrary S3 keys they do not own.
- Enable S3 CORS only for your domain; restrict methods to `PUT`.

**Example Code:**
```typescript
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { randomUUID } from 'crypto';

const s3 = new S3Client({ region: process.env.AWS_REGION });

export async function createPresignedUpload(userId: string, contentType: string, ext: string) {
  const fileKey = `uploads/${userId}/${randomUUID()}.${ext}`;
  const command = new PutObjectCommand({
    Bucket: process.env.S3_BUCKET,
    Key: fileKey,
    ContentType: contentType,
  });

  const uploadUrl = await getSignedUrl(s3, command, { expiresIn: 300 }); // 5 minutes
  return { uploadUrl, fileKey };
}

export async function confirmUpload(userId: string, fileKey: string) {
  // Verify ownership: key must start with uploads/{userId}/
  if (!fileKey.startsWith(`uploads/${userId}/`)) throw new Error('Forbidden');
  // Verify the file actually exists in S3 before creating the DB record
  // (HeadObject call omitted for brevity)
  return db.file.create({ data: { userId, key: fileKey, status: 'uploaded' } });
}
```

**Common Mistakes:**
- Letting the client choose the S3 key — allows overwriting other users' files.
- Not validating content type server-side — clients can upload any file type regardless of what the frontend checks.
- Skipping the confirm step — clients can link S3 keys they didn't upload.

**Security Considerations:**
- Set a short TTL (5 minutes) on presigned URLs.
- Use a separate S3 bucket for user uploads, not the same bucket as application assets.
- Block public access on the upload bucket — files should only be accessible via pre-signed GET URLs or through a CDN.

**Testing Strategy:**
Assert the presigned URL is scoped to the correct key. Test that attempting to upload to a different key with the same URL fails. Test confirm rejects keys belonging to other users.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: CDN-backed Assets

**Problem:** Serving files directly from S3 is slow for geographically distributed users, expensive per-request, and exposes the bucket URL.

**Solution:** Place a CDN (CloudFront, Cloudflare) in front of S3. The CDN caches files at edge locations globally. All asset URLs point to the CDN domain, never to S3 directly.

**Architecture:**
```
User  →  https://cdn.acme.com/uploads/abc.jpg
CDN   →  cache hit: serve from edge (< 10ms)
      →  cache miss: fetch from S3 → cache → serve
S3    →  private bucket, only accessible by CDN origin access control
```

**Implementation Notes:**
- Use CloudFront Origin Access Control (OAC) to restrict S3 bucket access to CloudFront only — no public S3 URLs.
- Set cache headers: `Cache-Control: public, max-age=31536000, immutable` for content-addressed files (hash in filename). Use short TTLs for mutable assets.
- Use signed URLs or signed cookies (CloudFront) for private/authenticated assets instead of leaving them public.
- Invalidate specific paths on update, not `/*` — full invalidations are slow and expensive.

**Example Code:**
```typescript
import { CloudFrontClient, CreateInvalidationCommand } from '@aws-sdk/client-cloudfront';
import { getSignedUrl } from '@aws-sdk/cloudfront-signer';

const cf = new CloudFrontClient({ region: 'us-east-1' });

// For private files: generate a signed CDN URL
export function getPrivateAssetUrl(key: string, expiresInSeconds = 3600) {
  return getSignedUrl({
    url: `${process.env.CDN_BASE_URL}/${key}`,
    keyPairId: process.env.CF_KEY_PAIR_ID!,
    privateKey: process.env.CF_PRIVATE_KEY!,
    dateLessThan: new Date(Date.now() + expiresInSeconds * 1000).toISOString(),
  });
}

// Invalidate a specific file after update
export async function invalidateAsset(key: string) {
  await cf.send(new CreateInvalidationCommand({
    DistributionId: process.env.CF_DISTRIBUTION_ID!,
    InvalidationBatch: {
      CallerReference: `${key}-${Date.now()}`,
      Paths: { Quantity: 1, Items: [`/${key}`] },
    },
  }));
}
```

**Common Mistakes:**
- Serving all assets with `Cache-Control: no-cache` — defeats the purpose of a CDN.
- Using `/*` invalidation every time any file changes — slow and expensive.
- Making the S3 bucket public — bypasses CDN and exposes storage URLs and pricing.

**Security Considerations:**
- Enforce HTTPS-only on the CDN distribution.
- Use signed URLs for any user-specific or paid content.
- Enable CDN access logs for auditing who accessed which assets.

**Testing Strategy:**
Verify the S3 bucket rejects direct public access. Test cache-hit responses include `X-Cache: Hit from cloudfront`. Test signed URL expiry returns 403 after the TTL.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: File Processing Pipeline

**Problem:** User-uploaded files (images, videos, documents) need post-processing (resize, transcode, virus scan) that is too slow and resource-intensive to run synchronously.

**Solution:** On upload confirmation, enqueue a processing job. Workers pick up the job, perform transformations, write outputs back to storage, and update the DB record status. Notify the user when done.

**Architecture:**
```
Upload confirmed  →  enqueue ProcessFileJob { fileKey, userId }
Worker            →  download file from S3
                  →  run transformations (resize, generate thumbnail)
                  →  upload results to S3 under derived keys
                  →  UPDATE file SET status='ready', thumbnailKey=...
                  →  send notification to user
```

**Implementation Notes:**
- Track file status: `pending` → `processing` → `ready` | `failed`.
- Process idempotently: derive output keys from the input key so reprocessing produces the same output key.
- Use a separate worker pool from the API server to isolate CPU-intensive work.
- Set job timeout; mark as `failed` if exceeded; support manual requeue.

**Example Code:**
```typescript
import sharp from 'sharp';
import { S3Client, GetObjectCommand, PutObjectCommand } from '@aws-sdk/client-s3';

async function processImageJob(fileKey: string) {
  await db.file.update({ where: { key: fileKey }, data: { status: 'processing' } });

  try {
    // Download
    const { Body } = await s3.send(new GetObjectCommand({ Bucket: process.env.S3_BUCKET!, Key: fileKey }));
    const buffer = Buffer.from(await Body!.transformToByteArray());

    // Process
    const thumbnail = await sharp(buffer).resize(200, 200, { fit: 'cover' }).jpeg({ quality: 80 }).toBuffer();
    const thumbnailKey = fileKey.replace('uploads/', 'thumbnails/').replace(/\.[^.]+$/, '.jpg');

    // Upload output
    await s3.send(new PutObjectCommand({
      Bucket: process.env.S3_BUCKET!, Key: thumbnailKey,
      Body: thumbnail, ContentType: 'image/jpeg',
    }));

    await db.file.update({ where: { key: fileKey }, data: { status: 'ready', thumbnailKey } });
  } catch (err) {
    await db.file.update({ where: { key: fileKey }, data: { status: 'failed', error: String(err) } });
    throw err; // let the queue handle retry
  }
}
```

**Common Mistakes:**
- Processing files synchronously in the upload handler — timeouts on large files.
- Not updating status to `failed` on error — files get stuck in `processing` forever.
- Storing processing outputs under the same key as the input — overwrites the original.

**Security Considerations:**
- Virus-scan uploaded files before making them accessible to other users.
- Validate file magic bytes (not just extension) before processing.

**Testing Strategy:**
Test happy path produces the correct output key and status. Test failure path sets `failed` status and the error message. Test reprocessing an already-processed file is idempotent.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Storage Tiering

**Problem:** Storing all files in standard S3 storage is expensive. Most files are accessed frequently at first, then rarely — but keeping them in the same tier wastes money.

**Solution:** Use S3 Intelligent-Tiering or explicit lifecycle rules to transition objects to cheaper storage classes (Infrequent Access, Glacier) after a specified inactivity period.

**Architecture:**
```
Day 0-30:   S3 Standard          (frequent access, low latency)
Day 30-90:  S3 Standard-IA       (infrequent access, lower cost)
Day 90+:    S3 Glacier Instant   (rare access, very low cost, ~ms retrieval)
Day 365+:   S3 Glacier Deep      (archival, hours to retrieve)
```

**Implementation Notes:**
- Set lifecycle rules via CloudFormation/Terraform — not manually in the console.
- Use S3 Intelligent-Tiering for workloads where access patterns are unpredictable.
- Factor in retrieval costs when transitioning — Glacier has per-retrieval fees.
- Tag objects with metadata (`project`, `type`) to apply different policies per file type.

**Example Code:**
```typescript
// Terraform / CDK — define via IaC, not SDK at runtime
// CDK example:
import * as s3 from 'aws-cdk-lib/aws-s3';

const bucket = new s3.Bucket(this, 'AssetsBucket', {
  lifecycleRules: [{
    transitions: [
      { storageClass: s3.StorageClass.INFREQUENT_ACCESS, transitionAfter: Duration.days(30) },
      { storageClass: s3.StorageClass.GLACIER_INSTANT_RETRIEVAL, transitionAfter: Duration.days(90) },
    ],
    expiration: Duration.days(730), // delete after 2 years
  }],
});
```

**Common Mistakes:**
- Transitioning to Glacier for files that users might need immediately — retrieval can take minutes/hours.
- Ignoring minimum storage duration charges (S3-IA has a 30-day minimum).
- Not excluding frequently-accessed data types (thumbnails, avatars) from aggressive tiering rules.

**Security Considerations:**
- Tiering policies do not affect encryption or access controls — verify bucket policies still apply to all tiers.
- Ensure delete markers are created for versioned buckets, not just the current version.

**Testing Strategy:**
Validate lifecycle rules with AWS CLI (`s3api get-bucket-lifecycle-configuration`). Spot-check that files older than the transition threshold show the expected storage class in S3 metadata.

**Score:** TBD (see pattern-lifecycle.md)
