# Sign-in UX — friction reduction without excluding users

**Video source:** https://www.instagram.com/reel/DgI9usSyEJG/ (complete transcript recovered 2026-11-25).

## What the creator actually recommends

Remove redundant tabs, make Apple and Google sign-in prominent, reduce marketing copy, add a real artwork element, position high-value controls more reachably, retain visible links to privacy policy and terms, and show which method was last used.

## Evidence-based implementation

- **Avoid forcing social OAuth only:** support a clear, accessible alternate email method for people without Apple/Google identities or unable to use provider login. Hiding the email fields behind a button may simplify the first screen; measure whether it impedes accessibility and completion.
- **Keyboard and screen reader support:** all controls need proper labels, visible focus, full keyboard operation, understandable errors and focus recovery; see https://www.w3.org/WAI/fundamentals/accessibility-principles/ and https://www.w3.org/WAI/WCAG22/Techniques/html/H102
- **Reachability is device/context-dependent:** review mobile small-screen reach, RTL layout, responsive keyboard overlays, screen zoom and touch targets.
- **Privacy and terms remain accessible:** do not conceal data use or consent obligations; 'last used' should not leak authentication information across shared devices.
- **Review with evidence:** track sign-in method completion and abandonment by platform, accessibility audit and tests with supported auth providers.

The Reel's statement that 'nobody really uses email' is an opinion, not universal data. Test user needs rather than removing options for aesthetics.

## Related operational tools

Opt-in `hallmark`, `impeccable`, `ui-sdk-agent`, `ui-sdk-react` and `shadcn-mcp` are registered in `INSTALL-PROFILES.json`; actual installed status must be checked per host/project.
