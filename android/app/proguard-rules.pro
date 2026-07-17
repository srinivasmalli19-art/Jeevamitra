# android/app/build.gradle.kts sets isMinifyEnabled = true for the release
# build type and references this file — without it, `flutter build appbundle`
# / `flutter build apk --release` fails immediately with a missing-file error
# from R8/proguardFiles(). Keep this file even if it stays mostly empty.

# Flutter embedding (normally covered by Flutter's own consumer rules, kept
# here as a defensive belt-and-suspenders measure).
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase (Auth / Firestore / Storage / Messaging / Crashlytics / Performance
# / Remote Config / Analytics) — the SDKs ship their own consumer-proguard
# rules, but Play Integrity's attestation classes have been seen stripped in
# aggressive R8 configs, which silently breaks phone-auth verification. Keep
# them explicitly.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Play Integrity (used by Firebase Phone Auth app attestation on Android).
-keep class com.google.android.play.core.integrity.** { *; }
-dontwarn com.google.android.play.core.integrity.**

# Play Core split-install / deferred-components classes are referenced by
# Flutter's engine (PlayStoreDeferredComponentManager) even though this app
# doesn't use Play Feature Delivery. Without this, R8 fails the release build
# with "Missing class com.google.android.play.core.splitinstall...".
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
