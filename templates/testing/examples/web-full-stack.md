# Example — Full-stack web qualification

Capability: **customer completes checkout and receives paid access**.

Required evidence: build/typecheck/lint; browser checkout in provider test mode; authenticated webhook; DB subscription written exactly once; fresh authenticated request sees entitlement; duplicate webhook is idempotent; invalid signature is rejected for the expected reason; failures appear in logs without secrets.

```ts
test("paid entitlement survives checkout", async ({ page, request }) => {
  await page.goto("/pricing");
  await page.getByRole("button", { name: "Upgrade" }).click();
  await completeProviderTestCheckout(page);
  await expect(page.getByText("Subscription active")).toBeVisible();
  const entitlement = await request.get("/api/me/entitlements");
  expect(entitlement.ok()).toBeTruthy();
  expect(await entitlement.json()).toMatchObject({ plan: "pro", active: true });
});
```

The authoritative DB/webhook assertion belongs in an integration or test-only verification path, not a privileged browser endpoint.
