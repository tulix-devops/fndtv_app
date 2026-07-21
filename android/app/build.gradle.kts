import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.fndtv.videoplayer"
    compileSdk = 35  // Latest Android API level (Android 15)
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.fndtv.videoplayer"
        minSdk = flutter.minSdkVersion  // Android 5.0 (Lollipop) - good compatibility
        targetSdk = 35  // Latest Android API level
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = false
            isShrinkResources = false
            // Disable ProGuard for now to avoid R8 compilation issues
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
    }

    // `normal` = the regular app. `stb` = the set-top box kiosk build, whose
    // home-launcher manifest + native components live in src/stb/, so ordinary
    // (dev/emulator) builds are never turned into a launcher.
    // NOTE: once flavors exist Flutter requires --flavor, e.g.
    //   flutter run        --flavor normal
    //   flutter build apk  --flavor stb --release
    flavorDimensions += "target"
    productFlavors {
        create("normal") {
            dimension = "target"
            isDefault = true
        }
        create("stb") {
            dimension = "target"
            // Same applicationId + signing as normal, so device registration and
            // release signing carry over unchanged.
        }
    }
}

flutter {
    source = "../.."
}
