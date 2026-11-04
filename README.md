# Spy Imposter Game

A pass-the-phone social deduction party game. Everyone knows the secret word. One of you doesn't.

Same rules and flow as the original pass-the-phone party game, with a dark spy theme. The word pack and ad behavior are unchanged.

## How it works

1. Add 3–20 agent names
2. Configure difficulty, imposters, and optional hints
3. Pass the phone — each agent long-presses to privately open their dossier
4. Discuss and give clues **outside the app**
5. Tap **Play again** for a fresh word and new imposters

## Product rules baked in

- Imposters are never Agent 1 or Agent 2 (player positions 1 and 2)
- Starting agent is chosen independently of imposter selection
- Imposters never see the secret word
- Secrets hide when the app is backgrounded

## Stack

- Flutter + Riverpod. Navigation is a single screen driven by `GamePhase` (the `go_router` dependency is declared, matching the original project, and is not used for routes)
- Offline 600-word pack (`assets/data/imposter_words.json`)
- SharedPreferences for settings
- Bundled fonts, no runtime download: Stardos Stencil (display), Courier Prime (dossier labels), Nunito (body), Oswald (numbers). Each ships with its SIL Open Font License under `assets/fonts/`

## Run

```bash
flutter pub get
flutter run
flutter test
```

## Icons

Launcher icons are generated from `assets/icon/` with `flutter_launcher_icons`:

```bash
dart run flutter_launcher_icons
```

## Release signing

Android release builds read `android/key.properties` (not committed). It points at an upload keystore that also stays out of the repo. `android/app/build.gradle.kts` sets `versionCode` and `versionName` from `flutter.versionCode` and `flutter.versionName`. There is no Play deploy workflow in this repository yet.

Do not commit keystores, passwords, or Play service-account JSON.

## Configuring AdMob for release

**This app does not have its own AdMob app or ad units yet.** [`config/admob.json`](config/admob.json) contains Google's public sample IDs (`ca-app-pub-3940256099942544…`) for Android and iOS. Debug and profile builds always request those sample units. A release build refuses to ship them.

Create the Spy Imposter Game apps and ad units in AdMob, then replace every value in `config/admob.json` before a release build. The release checker expects IDs for publisher `ca-app-pub-8661918790125012` (the same publisher account the original game uses). Sample IDs and `TODO_…` placeholders fail that check on purpose.

| JSON key | What to paste | Where it is used |
| --- | --- | --- |
| `ADMOB_ANDROID_APP_ID` | Android app ID (`ca-app-pub-…~…`) | Android manifest app ID |
| `ADMOB_ANDROID_BANNER_ID` | Android banner unit | Home and the between-rounds screen |
| `ADMOB_ANDROID_INTERSTITIAL_ID` | Android interstitial unit | Between rounds, every 4th Play again, at least 90 seconds apart |
| `ADMOB_IOS_APP_ID` | iOS app ID | Info.plist `GADApplicationIdentifier` |
| `ADMOB_IOS_BANNER_ID` | iOS banner unit | Home and the between-rounds screen |
| `ADMOB_IOS_INTERSTITIAL_ID` | iOS interstitial unit | Between rounds, every 4th Play again, at least 90 seconds apart |

Register both apps under that publisher:

- Android package `com.the_lazy_bear_club.spy_imposter_game`
- iOS bundle `com.thelazybearclub.spyImposterGame`

There is no rewarded ad.

Where those values are applied:

- **Dart ad units** read `config/admob.json` (it is a bundled asset). You can override any key at compile time with `--dart-define` or `--dart-define-from-file=config/admob.json`.
- **Android App ID** is injected into `AndroidManifest.xml` as `${admobAppId}`. Gradle reads `ADMOB_ANDROID_APP_ID` from the JSON for release, and Google's sample App ID for debug and profile.
- **iOS App ID** is `$(GAD_APPLICATION_IDENTIFIER)` in `ios/Runner/Info.plist`. Debug and profile xcconfigs pin the sample App ID. Release reads `ios/Flutter/AdMob.xcconfig`, which is generated from the JSON:

```bash
dart run tool/sync_admob.dart
```

Run that after every edit to the iOS App ID. A release iOS build fails if the xcconfig is stale.

Release builds fail, instead of silently shipping test ads, when an ID is empty, still a `TODO_…` placeholder, or still one of Google's sample IDs:

- `flutter build appbundle` / `flutter build apk --release` runs `dart run tool/validate_admob.dart --android` before packaging.
- Xcode Release runs `tool/validate_admob_ios.sh`.
- The release app itself throws on startup if the current platform's IDs are still invalid.

`flutter test`, `flutter analyze`, and debug or profile builds do not run that check, so the committed sample IDs are fine for development.

Android can ship before the iOS IDs exist. The Android check only looks at the Android keys, and the iOS check only looks at the iOS keys.

Ads are not shown during the pass-the-phone role reveal. On launch, the app requests UMP consent before initializing Mobile Ads. If consent is not required, or the consent check fails or times out without an actual denial, Mobile Ads still starts. Ads stay off only when consent is required and the user has not granted it. If a privacy-options entry point is required, Settings shows **Ad privacy choices**.
