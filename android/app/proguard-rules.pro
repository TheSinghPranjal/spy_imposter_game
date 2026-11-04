# Keep rules for Google Mobile Ads and UMP. Applied only if release
# minification is turned on. R8 is the Android Gradle Plugin shrinker.
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-keep class com.google.android.ump.** { *; }
-dontwarn com.google.android.gms.ads.**
-dontwarn com.google.android.ump.**
