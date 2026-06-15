# Mobile Frameworks & Platforms

## Overview
Consult this guide when starting a mobile project or evaluating whether to go cross-platform or native. Key dimensions: team language familiarity, OTA update requirements, access to native APIs, app store review constraints, and performance targets.

**Decision heuristic:**
- React/JS team + managed workflow + OTA updates → Expo
- React/JS team + custom native modules required → React Native (bare)
- Single codebase + near-native performance + Dart OK → Flutter
- iOS-only + maximum platform integration → Swift (Native iOS)
- Android-only + maximum platform integration → Kotlin (Native Android)

**OTA updates note:** Apple App Store policies restrict executable code delivery outside the app binary. OTA JS bundle updates (Expo EAS Update, CodePush) are permitted for React Native / Expo because JS is interpreted, not compiled native code. Flutter and native apps cannot use OTA for compiled code changes.

## Frameworks

### Expo (React Native — Managed)
**Type:** Cross-platform (iOS + Android)
**Language:** JavaScript / TypeScript
**Best For:** React/JS teams that want the fastest path to a production mobile app with OTA update capability and minimal native toolchain setup.
**Official Docs:** https://docs.expo.dev
**GitHub:** https://github.com/expo/expo
**Key Strengths:**
- Managed workflow abstracts iOS/Android build toolchains — no Xcode or Android Studio required for most workflows
- EAS Update enables OTA JavaScript bundle delivery, bypassing app store review for JS-only changes
- EAS Build provides cloud-based native builds without local environment setup
- Large library of pre-built modules (camera, notifications, location, etc.) with consistent cross-platform APIs
- Expo Go app allows instant preview on physical devices without a build step
- Snack playground for rapid prototyping without local install
**Watch Out For:**
- Native modules not in the Expo SDK require ejecting to bare workflow or using EAS Build with a custom dev client
- App binary size is larger than bare React Native because the managed runtime bundles unused modules
- Some low-level native APIs (Bluetooth, background audio, VoIP) may require ejecting or custom plugins
- OTA updates are JS-only; native changes still require a full app store submission

---

### React Native (Bare)
**Type:** Cross-platform (iOS + Android)
**Language:** JavaScript / TypeScript (with native modules in Swift/Objective-C and Kotlin/Java)
**Best For:** React/JS teams that need full access to native modules, third-party SDKs, or custom native code while sharing a single JS codebase.
**Official Docs:** https://reactnative.dev/docs/getting-started
**GitHub:** https://github.com/facebook/react-native
**Key Strengths:**
- Full access to native iOS and Android APIs via native modules and the New Architecture (JSI/Turbo Modules)
- OTA JS bundle delivery via Microsoft CodePush (App Center) or Expo EAS Update
- Large ecosystem of third-party native modules (React Native Directory)
- Bridge to any native SDK without framework restrictions
- React paradigm shared with web — team cross-skilling is easier
- New Architecture (Fabric renderer + Turbo Modules) significantly reduces bridge overhead
**Watch Out For:**
- Requires local Xcode and Android Studio setup; build environment is more brittle than Expo managed
- Upgrading React Native versions between major releases can be disruptive
- JavaScript bridge (Old Architecture) introduces latency for high-frequency native calls; mitigated by New Architecture but migration may be needed
- Third-party library quality varies; check maintenance status before adopting
- OTA updates are JS-only; native changes require a full app store submission

---

### Flutter
**Type:** Cross-platform (iOS, Android, Web, Desktop)
**Language:** Dart
**Best For:** Teams willing to learn Dart who want near-native performance, pixel-perfect custom UI, and a single codebase across platforms beyond just mobile.
**Official Docs:** https://docs.flutter.dev
**GitHub:** https://github.com/flutter/flutter
**Key Strengths:**
- Renders UI via its own Skia/Impeller graphics engine — not platform widgets — giving consistent pixel-perfect appearance across platforms
- Compiled to native ARM code; startup and animation performance is excellent
- Single codebase targets iOS, Android, Web, Windows, macOS, and Linux
- Hot reload and hot restart for fast development iteration
- Rich set of Material and Cupertino widgets out of the box
- Strong typing and null safety in Dart reduce runtime errors
**Watch Out For:**
- Dart is not widely known outside the Flutter ecosystem; team onboarding cost is real
- Cannot deliver OTA updates for compiled Dart code changes; app store submission required for every native code change
- Platform-specific look and feel requires deliberate effort — default widgets match Material Design, not iOS HIG
- App binary size is larger than native equivalents
- Interop with native platform code (platform channels) adds complexity for custom integrations
- Web support is present but not a first-class target for production-grade apps compared to native frameworks

---

### Swift (Native iOS)
**Type:** Native iOS (and macOS, watchOS, tvOS, visionOS)
**Language:** Swift
**Best For:** iOS-only projects that require maximum platform integration, cutting-edge Apple API access, or the highest possible performance and platform fidelity.
**Official Docs:** https://developer.apple.com/documentation/swift
**GitHub:** https://github.com/swiftlang/swift
**Key Strengths:**
- Full and immediate access to every Apple platform API — ARKit, Core ML, HealthKit, StoreKit, Metal, etc.
- Best-in-class SwiftUI declarative UI framework with live previews in Xcode
- Highest possible runtime performance for compute-heavy tasks
- Smallest binary size among iOS options
- Apple's preferred language — receives first-party tooling, documentation, and WWDC sessions
- Swift Concurrency (async/await, actors) for safe, readable asynchronous code
**Watch Out For:**
- iOS-only; requires separate Android codebase (Kotlin) for cross-platform reach
- No OTA updates for compiled Swift code; every change requires App Store review (except remote config/feature flags for non-executable content)
- Xcode is required and macOS-only; Linux/Windows developers cannot contribute natively
- SwiftUI still has rough edges for complex layouts; UIKit interop is sometimes necessary
- Swift version upgrades can introduce breaking changes in the compiler

---

### Kotlin (Native Android)
**Type:** Native Android
**Language:** Kotlin
**Best For:** Android-only projects that require maximum Google platform integration, Play Store-specific features, or the best possible performance and platform fidelity on Android.
**Official Docs:** https://developer.android.com/kotlin
**GitHub:** https://github.com/JetBrains/kotlin
**Key Strengths:**
- Full and immediate access to every Android API — CameraX, WorkManager, Room, Compose, Google Pay, etc.
- Jetpack Compose is Google's modern declarative UI toolkit, deeply integrated with Android tooling
- Kotlin Coroutines and Flow provide structured concurrency with excellent tooling support
- Highest possible runtime performance for compute-heavy Android workloads
- Google's preferred language for Android — all new Jetpack APIs are Kotlin-first
- Strong interoperability with existing Java codebases
**Watch Out For:**
- Android-only; requires separate iOS codebase (Swift) for cross-platform reach
- No OTA updates for compiled Kotlin/JVM bytecode; every change requires Play Store review (except remote config for non-executable content)
- Android fragmentation across device manufacturers and OS versions adds testing overhead
- Jetpack Compose is maturing rapidly; APIs change between versions and some advanced UI patterns lack documentation
- Build times with Gradle can be slow on large projects

---

## Cross-Platform vs Native Decision Matrix

| Criterion | Expo | RN Bare | Flutter | Swift | Kotlin |
|---|---|---|---|---|---|
| Single codebase | ✓ | ✓ | ✓ | ✗ | ✗ |
| OTA JS updates | ✓ | ✓ | ✗ | ✗ | ✗ |
| Native module access | limited | ✓ | ✓ | ✓ | ✓ |
| Startup performance | good | good | excellent | excellent | excellent |
| Team skill: JS/TS | ✓ | ✓ | ✗ | ✗ | ✗ |
| Team skill: Dart | ✗ | ✗ | ✓ | ✗ | ✗ |
| App Store compliant | ✓ | ✓ | ✓ | ✓ | ✓ |

## Official Starter Templates

| Framework | Starter Repository | Stars |
|---|---|---|
| Expo | [expo/expo/templates](https://github.com/expo/expo/tree/main/templates) | 36k+ |
| React Native | [infinitered/ignite](https://github.com/infinitered/ignite) | 15k+ |
| Flutter | [flutter/samples](https://github.com/flutter/samples) | 17k+ |
| Expo (production) | [obytes/react-native-template-obytes](https://github.com/obytes/react-native-template-obytes) | 3k+ |
