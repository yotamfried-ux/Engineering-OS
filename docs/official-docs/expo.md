# Expo — Official Documentation Index

## Official Documentation
**Primary:** https://docs.expo.dev/
**SDK API Reference:** https://docs.expo.dev/versions/latest/
**GitHub:** https://github.com/expo/expo
**Changelog:** https://expo.dev/changelog

## Key Sections (Recommended Reading Order)

1. [Get Started](https://docs.expo.dev/get-started/introduction/) — `npx create-expo-app`, choosing between Expo Go and development builds; sets the mental model for the rest of the docs
2. [Expo Router — Introduction](https://docs.expo.dev/router/introduction/) — File-based routing for native and web from one codebase; the recommended navigation approach since SDK 50
3. [Expo Router — Layouts](https://docs.expo.dev/router/layouts/) — `_layout.tsx`, stack, tabs, modals, drawers; core patterns for every app shell
4. [Development Builds](https://docs.expo.dev/develop/development-builds/introduction/) — Custom native builds required whenever a library includes native code not bundled in Expo Go
5. [EAS Build](https://docs.expo.dev/build/introduction/) — Cloud build service for iOS and Android; covers `eas.json` profiles, credentials, and environment variables
6. [EAS Submit](https://docs.expo.dev/submit/introduction/) — Automated App Store and Google Play submission from CI; read after EAS Build
7. [EAS Update](https://docs.expo.dev/eas-update/introduction/) — Over-the-air JS bundle updates without a new store release; understand the channel/branch model before using
8. [Config Plugins](https://docs.expo.dev/config-plugins/introduction/) — Modify `AndroidManifest.xml` and `Info.plist` without ejecting; required for any library with native setup steps
9. [Expo SDK API Reference](https://docs.expo.dev/versions/latest/) — Every `expo-*` package documented; check here before installing a third-party library for a native capability
10. [Environment Variables](https://docs.expo.dev/guides/environment-variables/) — `.env` files with EAS, `EXPO_PUBLIC_` prefix for client-side vars, secrets via EAS Secrets

## Important APIs / Concepts

- **`expo-router`** — File-system router; `app/` directory maps directly to routes for both native and web
- **`_layout.tsx`** — Defines navigator wrappers (Stack, Tabs, Drawer) for a route segment; not a screen itself
- **`Link` / `useRouter` / `useLocalSearchParams`** — Navigation primitives from `expo-router`; replace React Navigation's `useNavigation` in managed projects
- **`ExpoConfig` (`app.json` / `app.config.js`)** — Central project manifest; controls bundle ID, permissions, plugins, and build settings
- **Managed workflow** — Expo manages native projects; no `ios/` or `android/` folders in source control; Config Plugins handle customisation
- **Bare workflow** — Full native projects checked in; more control, more maintenance; only choose this when Managed cannot satisfy a requirement
- **EAS Build profiles** — `development`, `preview`, `production` defined in `eas.json`; development profile installs Expo Dev Client, not Expo Go
- **`expo-modules-core`** — Native module API for writing Swift/Kotlin wrapped in a JS API; prefer over raw React Native native modules

## Common Patterns

- File-based navigation with Expo Router — see [patterns/ui/README.md](../../patterns/ui/README.md)
- Auth flow (login screens, protected routes) — see [patterns/auth/README.md](../../patterns/auth/README.md)
- Mobile app scaffold — see [templates/mobile-apps/README.md](../../templates/mobile-apps/README.md)

## Related External Systems

- see [external-systems/expo/README.md](../../external-systems/expo/README.md)

## Gotchas & Version Notes

- **Expo Go does not support custom native modules** — any library with a Config Plugin or native code requires a development build
- **`EXPO_PUBLIC_` prefix is required** for environment variables accessible in JS; variables without it are build-time only and not embedded in the bundle
- **`expo install` instead of `npm install`** — automatically pins the correct version of Expo SDK packages; using `npm install` directly can create silent version mismatches
- **Config Plugins run at `expo prebuild` time, not at runtime** — changes take effect only after regenerating/rebuilding the native project
- **EAS Update channels are tied to build profiles** — a production build only receives updates from the `production` channel by default; misconfiguring this silently serves wrong bundles
- **`expo-router` version must match the Expo SDK version** — check the compatibility table in the Router docs before upgrading either independently
- **New Architecture (Fabric + JSI) is enabled by default in SDK 51+** — some third-party libraries are not yet compatible; check `reactnative.directory` for flags before enabling
- **OTA updates via EAS Update push JS/assets only** — native code changes always require a new binary build and store submission
