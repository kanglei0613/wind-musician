# Android / iOS Feature Parity Audit
_Generated: 2026-05-02_

---

## Audit Results by Area

### 1. Permissions ✅ (fixed gaps)

| Permission | iOS (Podfile GCC flags) | Android (AndroidManifest) | Status |
|---|---|---|---|
| Microphone | `PERMISSION_MICROPHONE=1` | `RECORD_AUDIO` | ✅ Both |
| Notifications | `PERMISSION_NOTIFICATIONS=1` | `POST_NOTIFICATIONS` | ✅ Both |
| Audio/Playback | `PERMISSION_AUDIO=1` | `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_MEDIA_PLAYBACK` + `WAKE_LOCK` | ✅ Both |
| Photos/Storage | `PERMISSION_PHOTOS=1`, `PERMISSION_STORAGE=1`, `PERMISSION_MEDIA_LIBRARY=1` | `READ_EXTERNAL_STORAGE` (≤API32), `WRITE_EXTERNAL_STORAGE` (≤API28), `READ_MEDIA_AUDIO`, `READ_MEDIA_IMAGES` | 🔧 **Fixed** |
| Internet | — | `INTERNET` | ✅ Android only (correct) |

**Gaps fixed:**
- Added `READ_EXTERNAL_STORAGE` (`maxSdkVersion="32"`) to AndroidManifest — needed by `file_picker` on Android ≤ 12
- Added `WRITE_EXTERNAL_STORAGE` (`maxSdkVersion="28"`) — needed on Android ≤ 9
- Added `READ_MEDIA_AUDIO` — replaces `READ_EXTERNAL_STORAGE` for audio on Android 13+
- Added `READ_MEDIA_IMAGES` — needed by `share_plus` and `file_picker` on Android 13+

---

### 2. Sign In ✅ (fixed gap)

| Feature | iOS | Android | Status |
|---|---|---|---|
| Google Sign In config | `GIDClientID` + `REVERSED_CLIENT_ID` URL scheme in Info.plist; SceneDelegate + AppDelegate URL handlers | `google-services.json` with `com.kanglei.wind_musician` (matches `applicationId` and namespace) | ✅ Both |
| Apple Sign In | Present (mandatory per App Store guideline 4.8) | Hidden in UI (`if (isIos)` guard in login_page.dart) | ✅ Correct platform split |
| Apple Sign In platform guard in service layer | N/A | `signInWithApple()` lacked `Platform.isIOS` check — silent crash risk if ever called from non-iOS path | 🔧 **Fixed** |
| Package name parity | `com.kanglei.wind-musician` (iOS bundle ID, hyphen) | `com.kanglei.wind_musician` (Android, underscore — consistent with `google-services.json`) | ✅ No mismatch |

**Gap fixed:**
- Added `if (!Platform.isIOS) throw UnsupportedError(...)` to `AuthService.signInWithApple()` in `lib/features/auth/services/auth_service.dart`. The login UI already hides the Apple button on Android, but the service-layer guard prevents a native crash if the method is ever reached from a non-iOS code path.

---

### 3. Background Audio ✅ (no gaps)

| Feature | iOS | Android |
|---|---|---|
| Background audio declaration | `UIBackgroundModes: audio` in Info.plist | `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_MEDIA_PLAYBACK` + `foregroundServiceType="mediaPlayback"` |
| Audio session / focus | `AVAudioSession .playback` + `.mixWithOthers` in `MetronomeEngine.swift.setupAudioSession()` | `AudioFocusHandler.kt` requests `AUDIOFOCUS_GAIN`; releases on stop |
| CPU keepalive | AVAudioEngine keeps CPU awake automatically | `PARTIAL_WAKE_LOCK` in `MetronomeService.kt` (3-hour max) |
| Service restart | AVAudioSession managed by OS | `START_STICKY` in `MetronomeService.onStartCommand()` |

No changes needed.

---

### 4. Metronome ✅ (no gaps)

| Feature | iOS | Android |
|---|---|---|
| Platform channel | `MetronomePlugin.swift` + `MetronomeEngine.swift` via `com.kanglei.wind_musician/metronome` | `MetronomeService.kt` + `MetronomeEngine.kt` via same channel name |
| Commands | `start`, `stop`, `updateBpm`, `updateTimeSig`, `setSoundType`, `setPitchVariant` | Same 6 commands |
| BPM range | 20–320 (from `AppConstants`) | Same constants |
| Beat callback | `onBeat` dispatched on `DispatchQueue.main` | `onBeat` posted to `mainHandler` (main looper) |
| Sound types | SINE, WOODBLOCK, STICK_CLICK, SNARE | Same 4 types |
| Pitch variants | 1–5 | 1–5 |
| Time signatures | numerator/denominator dynamic | Same |
| Notification channel | N/A (no foreground service on iOS) | `NotificationHelper.createChannel()` — previously hardcoded Chinese text | 🔧 **Fixed** (see §7) |

---

### 5. Tuner / Pitch Fork ✅ (no gaps)

| Feature | iOS | Android |
|---|---|---|
| Microphone permission request | `Permission.microphone.request()` via `permission_handler` | Same (works via `RECORD_AUDIO` in manifest) |
| Permanent denial handling | Opens app settings automatically | Same |
| Pitch fork audio | SoLoud (`flutter_soloud`); `_pitchForkChannel.invokeMethod('requestFocus').ignore()` is no-op (no handler on iOS — silently ignored) | Platform channel handler in `MainActivity.kt` acquires `PARTIAL_WAKE_LOCK` + `AudioFocus` |
| Audio focus for pitch fork | AVAudioSession with `.mixWithOthers` set in MetronomeEngine `init()` | `acquirePitchForkAudio()` / `releasePitchForkAudio()` with 30-min WakeLock |

No changes needed. The `.ignore()` call on the pitch_fork channel from iOS is correct and intentional.

---

### 6. Responsive UI / Layout ✅ (no gaps)

| Feature | iOS | Android |
|---|---|---|
| Drawer drag gesture | Always enabled | Disabled when `systemGestureInsets.left > 0` (gesture nav mode); hamburger icon shown instead |
| Back interception | `PopScope(canPop: false, onPopInvokedWithResult: ...)` | Same; requires `android:enableOnBackInvokedCallback="true"` ✅ present in manifest |
| Landscape lock | `UISupportedInterfaceOrientations: Portrait` in Info.plist | No manifest orientation lock needed — Flutter handles via `SystemChrome.setPreferredOrientations` if needed |
| SafeArea | Used in Drawer and screens | Same (Material SafeArea works on Android) |
| Apple Sign In button | Visible | Hidden via `if (isIos)` ✅ |

No changes needed.

---

### 7. Localization ✅ (fixed gap)

| Area | Status |
|---|---|
| All 4 ARB files (zh/en/ja/ko) | ✅ Identical key sets — no missing keys |
| iOS InfoPlist.strings | ✅ Present for all 4 locales |
| Android notification channel name | Was hardcoded `"節拍器"` (Chinese only) | 🔧 **Fixed** |
| Android notification title | Was hardcoded `"節拍器運行中"` (Chinese only) | 🔧 **Fixed** |
| Android app label | Was `"wind_musician"` (internal ID exposed in launcher/recents) | 🔧 **Fixed** |

**Gaps fixed:**
- `NotificationHelper.kt`: Channel name and notification title now use `context.getString(R.string.metronome_channel_name/desc/title)` instead of hardcoded Chinese.
- Created 4 Android string resource files:
  - `res/values/strings.xml` — English (default)
  - `res/values-zh/strings.xml` — 中文
  - `res/values-ja/strings.xml` — 日本語
  - `res/values-ko/strings.xml` — 한국어
- Fixed `android:label="wind_musician"` → `android:label="@string/app_name"` in AndroidManifest so the launcher, recents, and system settings display **"Wind Musician"** on all locales.

---

### 8. Notification Permission ✅ (no gaps)

| Feature | iOS | Android |
|---|---|---|
| Runtime permission request at startup | Not needed (no notification-based features on iOS) | `requestNotificationPermissionIfNeeded()` with `if (!Platform.isAndroid) return` guard ✅ |
| Per-feature check before metronome start | `checkAndRequestNotificationForMetronome()` returns `true` immediately on non-Android | Requests, handles `permanentlyDenied` with multilingual dialog ✅ |
| `POST_NOTIFICATIONS` in manifest | N/A | ✅ Present |

No changes needed.

---

### 9. Other ✅ (verified)

| Item | iOS | Android | Status |
|---|---|---|---|
| `android:enableOnBackInvokedCallback` | N/A | `"true"` in MainActivity declaration | ✅ Present |
| `applicationId` / namespace | `com.kanglei.wind-musician` | `com.kanglei.wind_musician` (consistent with google-services.json) | ✅ |
| `minSdk` | iOS 13 (Podfile) | `flutter.minSdkVersion` (Flutter default = 21) | ✅ ≥ 21 |
| `targetSdk` | N/A | `flutter.targetSdkVersion` (Flutter 3.x default = 34) | ✅ |
| iOS-only pubspec deps | `sign_in_with_apple` imported on Android but guarded in service + hidden in UI | — | 🔧 **Fixed** (platform guard added) |
| Localization service strings | Uses inline hardcoded locale switch (no BuildContext needed) | Same | ✅ Acceptable pattern |

---

## Files Changed

| File | Change |
|---|---|
| `android/app/src/main/AndroidManifest.xml` | Added 4 storage permissions; fixed `android:label` to use `@string/app_name` |
| `android/app/src/main/res/values/strings.xml` | **New file** — English default: `app_name`, `metronome_channel_name`, `metronome_channel_desc`, `metronome_notification_title` |
| `android/app/src/main/res/values-zh/strings.xml` | **New file** — Chinese strings |
| `android/app/src/main/res/values-ja/strings.xml` | **New file** — Japanese strings |
| `android/app/src/main/res/values-ko/strings.xml` | **New file** — Korean strings |
| `android/app/src/main/kotlin/…/NotificationHelper.kt` | Channel name, channel description, and notification title now use `context.getString(R.string.*)` |
| `lib/features/auth/services/auth_service.dart` | Added `import 'dart:io'`; added `Platform.isIOS` guard to `signInWithApple()` |

---

## Items Confirmed Correct (No Changes Needed)

- iOS `UIBackgroundModes: audio` ✅
- Android `MetronomeService` `START_STICKY` + `PARTIAL_WAKE_LOCK` ✅
- Android `android:enableOnBackInvokedCallback="true"` ✅
- Drawer gesture detection via `systemGestureInsets` ✅
- `PopScope` back interception ✅
- All 4 ARB locale files have identical key sets ✅
- `notification_permission_service.dart` Android-only guard ✅
- `google-services.json` package name matches `applicationId` ✅
- iOS `GIDClientID` + `REVERSED_CLIENT_ID` URL scheme ✅
- iOS SceneDelegate + AppDelegate Google Sign-In URL handlers ✅
- Pitch fork `releaseFocus` called on widget dispose (WakeLock leak prevention) ✅
- Metronome BPM range 20–320 identical on both platforms ✅
- Sound types (SINE/WOODBLOCK/STICK_CLICK/SNARE) and pitch variants (1–5) parity ✅
