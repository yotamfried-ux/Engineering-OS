# Messaging Integration Patterns

> Part of [`patterns/integrations/`](../README.md). Covers SMS and OTP verification via external messaging providers.
>
> **Related:** [`external-systems/`](../../../external-systems/) for provider-specific API references (Twilio, AWS SNS).
> See [`core/pattern-lifecycle.md`](../../../core/pattern-lifecycle.md) for scoring and lifecycle rules.

---

## Pattern: SMS Verification (OTP)

**Problem:** Phone number verification and SMS-based 2FA require sending a one-time passcode via SMS and validating it within a short window — without leaking the code, allowing brute force, or enabling replay attacks.

**Solution:** Generate a cryptographically random OTP, store a hash of it (not the raw value) in Redis with a TTL, send the raw OTP via an SMS provider (Twilio, AWS SNS), and validate the hash on submission. Delete the key after successful verification.

**Architecture:**
```
POST /auth/phone/send
  → validate E.164 phone format
  → check rate limit (max 3 sends per 10 min per phone)
  → generate 6-digit OTP (crypto.randomInt)
  → store SHA-256(OTP) in Redis with TTL 600s
  → send raw OTP via SMS provider

POST /auth/phone/verify
  → check rate limit (max 5 attempts per phone)
  → SHA-256(submitted_code) == Redis value?
    → yes: delete key → mark phone as verified → clear attempt counter
    → no:  increment attempt counter → if ≥ 3 failures, delete key (force resend)
```

**Implementation Notes:**
- Store the SHA-256 hash of the OTP in Redis, not the raw OTP. A Redis dump or unauthorized read does not expose active codes.
- Use `crypto.randomInt(100_000, 1_000_000)` (not `Math.random()`) for a cryptographically secure 6-digit code.
- 6-digit numeric OTPs are the usability standard — users type them on mobile keyboards; alphanumeric OTPs increase transcription errors.
- Rate-limit the **send** endpoint by phone number (max 3 sends per 10 minutes) and the **verify** endpoint (max 5 attempts per OTP window, then delete the key and force a resend).
- Use E.164 format (`+15551234567`) for all phone numbers. Validate with a library (`libphonenumber-js`) before sending.

**Example Code:**
```typescript
import twilio from 'twilio';
import crypto from 'crypto';

const client = twilio(process.env.TWILIO_ACCOUNT_SID!, process.env.TWILIO_AUTH_TOKEN!);

const OTP_TTL_SECONDS = 600;      // 10 minutes
const MAX_VERIFY_ATTEMPTS = 5;

function hashOtp(otp: string): string {
  return crypto.createHash('sha256').update(otp).digest('hex');
}

export async function sendVerification(phone: string): Promise<void> {
  // Rate limiting: max 3 sends per window (enforced upstream or via Redis counter)
  const otp = String(crypto.randomInt(100_000, 1_000_000)); // 6-digit, cryptographically random

  await redis.set(`otp:hash:${phone}`, hashOtp(otp), { EX: OTP_TTL_SECONDS });
  await redis.set(`otp:attempts:${phone}`, '0', { EX: OTP_TTL_SECONDS });

  await client.messages.create({
    to: phone,
    from: process.env.TWILIO_PHONE_NUMBER!,
    body: `Your verification code is ${otp}. It expires in 10 minutes.`,
  });
}

export async function verifyCode(phone: string, code: string): Promise<boolean> {
  const attempts = parseInt((await redis.get(`otp:attempts:${phone}`)) ?? '0', 10);

  if (attempts >= MAX_VERIFY_ATTEMPTS) {
    // Force resend — do not reveal why verification failed
    await redis.del(`otp:hash:${phone}`, `otp:attempts:${phone}`);
    return false;
  }

  const stored = await redis.get(`otp:hash:${phone}`);
  if (!stored) return false; // expired or never sent

  const inputHash = hashOtp(code);

  // Use timingSafeEqual to prevent timing attacks on the hash comparison
  const isMatch = stored.length === inputHash.length &&
    crypto.timingSafeEqual(Buffer.from(stored), Buffer.from(inputHash));

  if (!isMatch) {
    await redis.incr(`otp:attempts:${phone}`);
    if (attempts + 1 >= MAX_VERIFY_ATTEMPTS) {
      await redis.del(`otp:hash:${phone}`, `otp:attempts:${phone}`);
    }
    return false;
  }

  // Success: delete OTP so it cannot be reused
  await redis.del(`otp:hash:${phone}`, `otp:attempts:${phone}`);
  return true;
}

declare const redis: {
  set(key: string, value: string, options?: { EX?: number }): Promise<void>;
  get(key: string): Promise<string | null>;
  del(...keys: string[]): Promise<void>;
  incr(key: string): Promise<number>;
};
```

**Common Mistakes:**
- Storing the raw OTP in Redis instead of its hash — a Redis compromise exposes all active verification codes.
- Not deleting the OTP after successful verification — allows the same code to be reused within the TTL window.
- Using `Math.random()` for OTP generation — not cryptographically secure; predictable with enough observations.
- Not rate-limiting the verify endpoint — allows exhaustive enumeration of all 900,000 possible 6-digit codes within the TTL window.
- Comparing hashes with `===` instead of `crypto.timingSafeEqual` — opens a timing side-channel that reveals how many characters matched.

**Security Considerations:**
- Validate phone numbers in E.164 format before sending — reject malformed numbers to prevent SMS injection.
- Never log OTP values, even at debug level. Log only that a send was initiated, to which number (masked: `+1***1234`), and the outcome (sent/failed).
- Implement account-level lockout after repeated failed verification sessions, not just per-OTP attempt limiting.
- For 2FA use cases, require re-verification of the OTP after a session timeout — do not persist the "phone verified" flag indefinitely.

**Testing Strategy:**
- Test successful verification deletes both Redis keys.
- Test an expired OTP (TTL elapsed) returns false.
- Test incorrect code increments the attempt counter.
- Test that after `MAX_VERIFY_ATTEMPTS` failures, both keys are deleted and further attempts return false.
- Test rate limiting on the send endpoint blocks after 3 sends per window.
- Never use real phone numbers in tests — mock the Twilio client.

**Score:** Candidate

---

## Official References
- [Twilio Verify API](https://www.twilio.com/docs/verify/api) — managed OTP/verification service
- [Twilio Messaging API](https://www.twilio.com/docs/messaging/api) — raw SMS sending
- [AWS SNS SMS](https://docs.aws.amazon.com/sns/latest/dg/sns-mobile-phone-number-as-subscriber.html) — Amazon SNS for SMS
- [libphonenumber-js](https://github.com/catamphetamine/libphonenumber-js) — E.164 phone number parsing and validation
- [Node.js crypto.randomInt](https://nodejs.org/api/crypto.html#cryptorandomintmin-max-callback) — cryptographically secure integer generation
