import groovy.json.JsonSlurper
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Google's sample Android App ID. Debug and profile keep this so they only
// ever serve test ads. Must stay in sync with AdIds.sampleAndroidAppId.
val sampleAndroidAppId = "ca-app-pub-3940256099942544~3347511713"

fun loadAdmobConfig(): Map<String, String> {
    val file = rootProject.file("../config/admob.json")
    if (!file.exists()) return emptyMap()
    @Suppress("UNCHECKED_CAST")
    val parsed = JsonSlurper().parse(file) as Map<String, Any?>
    return parsed.mapValues { (_, value) -> value?.toString()?.trim().orEmpty() }
}

fun flutterSdkPath(): String {
    val properties = Properties()
    val file = rootProject.file("local.properties")
    if (file.exists()) {
        file.inputStream().use { properties.load(it) }
    }
    return properties.getProperty("flutter.sdk")
        ?: System.getenv("FLUTTER_ROOT")
        ?: throw GradleException(
            "Flutter SDK not found. Set flutter.sdk in android/local.properties.",
        )
}

fun validateReleaseAdMobIds() {
    val dart = file("${flutterSdkPath()}/bin/dart")
    if (!dart.exists()) {
        throw GradleException("Dart executable not found at ${dart.absolutePath}")
    }
    exec {
        workingDir = rootProject.projectDir.parentFile
        commandLine(dart.absolutePath, "run", "tool/validate_admob.dart", "--android")
    }
}

val releaseAndroidAppId = loadAdmobConfig()["ADMOB_ANDROID_APP_ID"].orEmpty()
    .ifBlank { "TODO_ADMOB_ANDROID_APP_ID" }

// Release signing details live in android/key.properties (not committed).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.the_lazy_bear_club.spy_imposter_game"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.the_lazy_bear_club.spy_imposter_game"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["admobAppId"] = sampleAndroidAppId
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            // Resolved relative to android/app, so "../upload-keystore.jks"
            // points at android/upload-keystore.jks.
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        getByName("debug") {
            manifestPlaceholders["admobAppId"] = sampleAndroidAppId
        }
        // Flutter creates this type from debug before this block runs.
        getByName("profile") {
            manifestPlaceholders["admobAppId"] = sampleAndroidAppId
        }
        release {
            signingConfig = signingConfigs.getByName("release")
            manifestPlaceholders["admobAppId"] = releaseAndroidAppId
            // R8 is AGP's shrinker. Minification stays off, matching the
            // Imposter project, so the Mobile Ads SDK is not stripped.
            // proguard-rules.pro is ready if a later release turns it on.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

// Fail release packaging if config/admob.json still has sample or placeholder
// IDs. Debug and profile are not checked, so sample IDs do not fail them.
tasks.configureEach {
    if (name == "bundleRelease" || name == "assembleRelease") {
        doFirst {
            validateReleaseAdMobIds()
        }
    }
}

flutter {
    source = "../.."
}
