import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Signing credentials for release builds. Kept out of the repo (see
// android/.gitignore) — a build without them falls back to the debug key,
// which Play will not take.
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "com.talkmos.app"
    // Compiled against the highest SDK any plugin needs — they are backward
    // compatible, and building lower fails outright: permission_handler_android
    // references API 37 constants (ACCESS_LOCAL_NETWORK), livekit_client needs
    // 36+.
    compileSdk = 37
    // API 37 ships as minor releases (android-37.0, android-37.1) — plain
    // `compileSdk = 37` looks for an "android-37" that no longer exists.
    compileSdkMinor = 0
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.talkmos.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storePath = keyProperties.getProperty("storeFile")
            if (storePath != null) {
                storeFile = file(storePath)
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Falls back to debug signing only where key.properties is absent,
            // so a checkout without the keystore still builds — a release that
            // has to be shipped is signed properly or it is not built at all.
            signingConfig = if (keyProperties.getProperty("storeFile") != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
