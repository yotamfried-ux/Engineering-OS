# GDPR and tracking consent — official-source research route

**Knowledge type:** privacy/legal engineering reference, not an installable tool. This is not legal advice. Applicability depends on users, establishments, processing, and local law; do not presume every app is subject to the same requirements.

## Primary official sources
- [GDPR consolidated regulation (EU 2016/679)](https://eur-lex.europa.eu/eli/reg/2016/679/oj)
- [European Data Protection Board — Guidelines 05/2020 on consent](https://www.edpb.europa.eu/our-work-tools/our-documents/guidelines/guidelines-052020-consent-under-regulation-2016679_en)
- [EDPB — Guidelines 2/2023 on technical scope of Art. 5(3) ePrivacy Directive](https://www.edpb.europa.eu/our-work-tools/our-documents/guidelines/guidelines-22023-technical-scope-art-53-eprivacy-directive_en)

## Task-based engineering review
1. Map data categories, processing purposes, recipients, retention and cross-border transfers; determine a lawful basis **per purpose**. Consent is one possible GDPR basis, not universally mandatory for every processing activity.
2. For non-essential device storage/access (cookies and similar technologies), assess applicable **ePrivacy** consent requirements separately from GDPR lawful-basis analysis. Block relevant trackers until a valid choice where required.
3. If relying on consent, require freely given, specific, informed, unambiguous affirmative action; record evidence and provide withdrawal as easily as giving consent. Avoid pre-ticked boxes or deceptive refusal paths.
4. Assess transparency notices, data-subject access/correction/deletion/portability rights and exceptions, processors/subprocessors and contracts, security controls, retention and deletion.
5. Assess breach-response duties and notification thresholds/time limits where applicable; don't assume every incident automatically requires regulator notice.
6. Test actual network calls before and after consent/rejection/withdrawal, persistence of choices, and end-to-end deletion workflows. Review with qualified legal counsel for jurisdiction-specific obligations.

Do not use a social creator's fixed-number checklist as authority or claim this page alone establishes compliance. Compare with existing repository legal/privacy guidance before implementation.
