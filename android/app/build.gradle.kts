plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "dev.fenron.bino_bit_notes"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Pflicht für flutter_local_notifications (nutzt Java-8-Time-API via Desugaring).
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "dev.fenron.bino_bit_notes"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // minSdk 23 (Android 6.0): SQLite 3.8.10+ mit FTS5-Garantie.
        // flutter.minSdkVersion wäre 21, aber ältere OEM-Builds haben
        // inkonsistente SQLite-Versionen. API 23+ deckt ~99% aller aktiven Geräte ab.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Desugar-Bibliothek: ermöglicht Java-8-APIs (java.time.*) auf Android < API 26.
    // Wird von flutter_local_notifications für zonedSchedule benötigt.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
