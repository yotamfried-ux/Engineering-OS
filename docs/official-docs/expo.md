# Expo — Official Documentation Index

## Official Documentation
**Primary:** https://docs.expo.dev/
**GitHub:** https://github.com/expo/expo
**Changelog:** https://github.com/expo/expo/blob/main/CHANGELOG.md

## Key Sections (Recommended Reading Order)
1. [Get Started](https://docs.expo.dev/get-started/introduction/) — Project creation with `create-expo-app`, choosing between Expo Go and dev builds.
2. [Expo Router](https://docs.expo.dev/router/introduction/) — File-based routing for native and web; the recommended navigation solution since SDK 50.
3. [Development Builds](https://docs.expo.dev/develop/development-builds/introduction/) — Custom native builds for dev; required when adding native modules not in Expo Go.
4. [EAS Build](https://docs.expo.dev/build/introduction/) — Cloud builds for iOS and Android; essential for CI/CD and App Store submission.
5. [EAS Submit](https://docs.expo.dev/submit/introduction/) — Automated App Store and Google Play submission from CI.
6. [EAS Update](https://docs.expo.dev/eas-update/introduction/) — OTA JavaScript bundle updates without App Store review.
7. [Config Plugins](https://docs.expo.dev/config-plugins/introduction/) — Modify native projects (AndroidManifest, Info.plist) without ejecting.
8. [Expo SDK API Reference](https://docs.expo.dev/versions/latest/) — All built-in modules (Camera, Location, Notifications, SecureStore, etc.).
9. [Environment Variables](https://docs.expo.dev/guides/environment-variables/) — `.env` files with EAS, secrets in EAS Build vs. client-side vars.

## Important APIs / Concepts
- **Expo Router** — File-based routing; `app/` directory mirrors URL structure for both native and web.
- **EAS (Expo Application Services)** — Cloud platform for Build, Submit, and Update; configured via `eas.json`.
- **Development Build** — A custom Expo Go variant that includes your project's native dependencies.
- **Config Plugin** — A function that modifies `app.json`/`app.config.js` and native project files at build time.
- **Managed Workflow** — Expo manages native code; no `android/` or `ios/` directories in source control.
- **Bare Workflow** — Full native project exposure; needed for deep native customization.
- **expo-modules-core** — Native module API for writing Kotlin/Swift modules that integrate with Expo.
- **app.config.js** — Dynamic config; prefer over `app.json` when you need environment-based values.
- **Prebuild** — `npx expo prebuild` generates native directories from config; run before bare workflow changes.

## Common Patterns
- File-based navigation with Expo Router — see [patterns/ui/README.md](../../patterns/ui/README.md)
- Auth flow (login screens, protected routes) — see [patterns/auth/README.md](../../patterns/auth/README.md)
- Push notifications setup — see [patterns/ui/README.md](../../patterns/ui/README.md)

## Related External Systems
- EAS Build / Submit — see [external-systems/expo/README.md](../../external-systems/expo/README.md)

## Gotchas & Version Notes
- Expo Go only supports modules included in the Expo SDK; any third-party native module requires a dev build.
- `expo-router` v3+ requires SDK 50+; layout files (`_layout.tsx`) define navigator wrappers, not screens.
- EAS Build uses separate `eas.json` profiles (`development`, `preview`, `production`); configure before first build.
- OTA updates via EAS Update only push JS/assets — native code changes always require a new build.
- iOS simulator builds cannot be submitted to App Store; use `eas build --platform ios` for archive builds.
- `EXPO_PUBLIC_` prefix is required for environment variables accessible in client-side code.
- Metro bundler is used by default; web support requires `@expo/webpack-config` or Metro web (SDK 50+).
- New Architecture (Fabric + JSI) is opt-in per SDK; check individual library compatibility before enabling.
