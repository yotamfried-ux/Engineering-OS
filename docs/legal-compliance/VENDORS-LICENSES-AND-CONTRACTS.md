# Vendors, cloud processors, IP, OSS licenses and AI contracts

## Why this matters

Using a third-party library, hosting service, analytics SDK, billing gateway or LLM API can create privacy, security, intellectual-property and contract duties. "It is on GitHub" does **not** mean "free to copy into a commercial product". Canonical sources: [EDPB controller/processor contracts](https://www.edpb.europa.eu/sme/learn-the-basics/data-controller-or-data-processor_en), [SPDX](https://spdx.org/licenses/), [GitHub's repository licensing guide](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository). External provider terms require current vendor review.

## Vendor / subprocessor matrix (one record per real integration)

```yaml
vendor: "<cloud/payments/email/analytics/crash/AI>"
service_and_role: "<purpose, controller/processor/subprocessor/independent>"
data_categories: ["<actual fields/content>"]
user_geographies: ["<target>"]
processing_locations: ["<actual and backups if known>"]
privacy_notice_disclosure: "<URL/version and user notice location>"
contract_and_dpa: "<signed agreement/version or pending>"
transfer_review: "<applicable law, mechanism, counsel outcome>"
subprocessor_changes: "<notices and approval channel>"
security_evidence: "<SOC report, controls, DPA annexes, not just vendor claims>"
deletion_export_support: "<actual API/process and verified behavior>"
breach_notification_contact: "<address/SLA as contracted>"
retention_and_training: "<configured and approved; include model prompts/media>"
owner: "<reviewer>"
status: "<APPROVED|REVIEW_REQUIRED|BLOCKED>"
```

**DPA review issues when relevant:** documented instructions and purposes; confidentiality; technical/organizational measures; subprocessor approval and change notices; rights assistance; incident notice deadlines; deletion or return; audit/support obligations; international transfers; term and termination. B2B SaaS roles vary by data type (for example account billing data vs customer end-user records).

## Open-source package & media asset audit

- Inventory runtime + build/dev + bundled/transitive dependencies with exact versions, repository, license, license text, notices and modification status (SBOM when useful).
- **License matters:** permissive MIT/Apache/BSD may require notices/attribution; GPL/AGPL and other copyleft can impose different source-disclosure or network-use duties when conditions apply; unknown/proprietary/no-license components need investigation **before use**. Do not give one-size-fits-all commercial-compatibility guarantees.
- **Noncode assets:** fonts (including embedding rights), icons, stock photos, illustrations, video, audio, data sets, UI templates, game assets and screenshots need their own license/consent and sometimes attribution. "Free to view" ≠ "free to reuse".
- **Generated AI material:** assess model/provider service terms, rights to inputs/outputs, third-party resemblance, training usage, licenses for training/example assets and intellectual-property risk; avoid promising exclusivity or non-infringement.
- **User uploads:** decide rights/licenses needed only to host/process/deliver, moderation/takedown/contact and responsibilities; avoid taking unnecessary broad perpetual ownership in Terms.
- **Code provenance:** keep notice files, license conditions, upstream URLs, modification records and permission to distribute commercially; test license-policy changes in CI, not blindly block all strong copyleft.

## Vendor/OSS release checks

- [ ] Actual SDK network behavior matches privacy notice and app store labels.
- [ ] DPAs/cross-border transfer arrangements inspected and lawyer-approved where needed.
- [ ] Vendors can action deletion/export and incident notices under contract.
- [ ] Permissions/roles least privilege, secrets in secret store, no private service key in frontend.
- [ ] OSS dependency scan includes **license and vulnerability** findings; obligations for statically/dynamically linked or network-served components researched.
- [ ] Media/fonts/data sourced with appropriate commercial license or original rights.
- [ ] AI provider configuration on logging, retention, model training and region documented — never assumed from marketing.
- [ ] Merchant-of-record/payment provider terms, refund/cancellation responsibilities and tax obligations reviewed.

**See also:** [source provenance](../../capability-registry/SOURCE-POLICY.md), [existing external systems catalog](../../external-systems/), [security tools](../../capability-registry/security/README.md).
