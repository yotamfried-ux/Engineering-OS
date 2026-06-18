# Mobile Application Template

## Overview
Use this template for cross-platform iOS and Android apps built with React Native and Expo. Appropriate when you need native device APIs, offline capability, and a shared codebase across platforms — especially when the team already knows JavaScript/TypeScript.

## Recommended Architecture Options

| Option | Pros | Cons |
|---|---|---|
| Expo (managed workflow) | Fast setup, OTA updates, unified toolchain | Some native modules unavailable without ejecting |
| Expo (bare workflow) | Full native access + Expo tooling | Requires Xcode/Android Studio for native changes |
| React Native CLI (no Expo) | Maximum native control | Slower setup, no OTA, manual module linking |
| Expo + NativeWind + tRPC | Full-stack type safety, shared schemas with web | More initial configuration |

## Recommended Frameworks & Platforms

- **Framework:** Expo SDK 51+, React Native 0.74+
- **Navigation:** Expo Router (file-based, recommended) or React Navigation 6
- **Styling:** NativeWind (Tailwind for RN) or StyleSheet API
- **State management:** Zustand (client), TanStack Query (server/async)
- **Local storage:** expo-secure-store (secrets), MMKV (fast key-value), SQLite via expo-sqlite
- **Auth:** Clerk Expo SDK, Supabase Auth, or custom JWT with expo-secure-store
- **Backend:** Shared API service (see api-service template) or Supabase
- **Push notifications:** Expo Notifications + FCM/APNs
- **OTA updates:** Expo Updates (EAS Update)
- **CI/CD:** EAS Build + EAS Submit

## Required Components

- Navigation stack with authenticated and unauthenticated routes
- Secure token storage (never AsyncStorage for auth tokens)
- Deep linking configuration
- Offline detection and graceful degradation
- Push notification permission request flow
- App version/update check on launch
- Crash reporting integration

## Security Checklist

- [ ] Auth tokens stored in expo-secure-store (Keychain/Keystore backed), not AsyncStorage
- [ ] Deep link handler validates and sanitizes all incoming URL parameters
- [ ] API calls use HTTPS only; certificate pinning considered for high-security apps
- [ ] No secrets or API keys in the app bundle — use environment variables + EAS Secrets
- [ ] Biometric/PIN lock implemented for sensitive screens
- [ ] Expo Updates channel locked to production for release builds
- [ ] Third-party SDK privacy manifest reviewed (required for iOS App Store)

## Testing Checklist

- [ ] Unit tests for business logic and hooks (Jest + React Native Testing Library)
- [ ] Component tests for critical screens (RNTL)
- [ ] Integration tests for navigation flows
- [ ] E2E tests on physical device or emulator (Maestro or Detox)
- [ ] Manual test on minimum supported iOS and Android versions
- [ ] Accessibility test: screen reader (VoiceOver/TalkBack) smoke check

## Deployment Checklist

- [ ] EAS Build profiles configured (development, preview, production)
- [ ] App signing credentials stored in EAS (not local machine)
- [ ] `app.json` version and buildNumber/versionCode incremented
- [ ] All EAS Secrets set for production environment
- [ ] TestFlight (iOS) and Internal Testing (Android) distribution verified before store submit
- [ ] App Store and Google Play metadata, screenshots, and privacy policy prepared
- [ ] OTA update rollout strategy defined (percentage rollout vs. immediate)

## Starter Templates

| Option | Description | Recommended |
|---|---|---|
| [infinitered/ignite](https://github.com/infinitered/ignite) | React Native CLI boilerplate with navigation, state, auth | ✅ Best pick |
| [expo/expo/templates/expo-template-default](https://github.com/expo/expo/tree/main/templates/expo-template-default) | Official Expo default template | |
| [obytes/react-native-template-obytes](https://github.com/obytes/react-native-template-obytes) | Expo + TypeScript + TailwindCSS React Native starter | |

**Best Pick:** [infinitered/ignite](https://github.com/infinitered/ignite) — 15k+ stars, production-tested, batteries-included with navigation, state management, auth, and testing wired up out of the box

## Reference Repositories

- [expo/expo](https://github.com/expo/expo) — official SDK, examples in `/apps` and `/examples`
- [expo/router](https://github.com/expo/router) — file-based routing reference and examples
- [infinitered/ignite](https://github.com/infinitered/ignite) — production-grade RN boilerplate with best practices

## Official Documentation

- [Expo Docs](https://docs.expo.dev) — SDK, EAS Build, EAS Submit, OTA updates
- [Expo Router Docs](https://docs.expo.dev/router/introduction/) — file-based routing for React Native
- [React Navigation Docs](https://reactnavigation.org/docs/getting-started) — navigation patterns
- [React Native Docs](https://reactnative.dev/docs/getting-started) — core components, native APIs
- [EAS Build Docs](https://docs.expo.dev/build/introduction/) — CI/CD for React Native
