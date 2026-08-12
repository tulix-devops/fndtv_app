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

// The `stb` RELEASE apk ships a single ABI. Without this it carries three
// (arm64-v8a + armeabi-v7a + x86_64) and libmpv.so alone is ~12 MB per ABI, so
// the apk lands at ~113 MB instead of ~47 MB. `--target-platform android-arm64`
// does NOT fix this: it only filters Flutter's own libflutter/libapp, while
// libmpv comes from the media_kit AAR and ships every ABI regardless.
//
// Why not `flutter build apk --split-per-abi`? That works, but Flutter offsets
// versionCode per ABI (arm64 -> 2005 instead of 5). With the in-app OTA
// updater (`/api/app-version/{id}/apk`) that is a trap: once a box is on 2005,
// a later non-split apk reads as a DOWNGRADE and Android refuses to install it.
// Filtering here keeps versionCode exactly what pubspec says.
//
// Scoped to stbRelease on purpose — stbDebug keeps every ABI so the x86_64
// Android TV emulator still works, and the `normal` (mobile) flavor keeps
// armeabi-v7a for older phones.
val isStbRelease = gradle.startParameter.taskNames.any {
    it.contains("stbRelease", ignoreCase = true)
}

// Any RELEASE apk (stb or normal). The normal release is what goes to the
// Amazon Appstore for Fire TV — every Fire TV device is ARM, so the Intel
// ABIs are dead weight there too. Debug builds keep x86_64 for the emulator.
val isReleaseBuild = gradle.startParameter.taskNames.any {
    it.contains("Release", ignoreCase = true)
}

android {
    namespace = "com.fndtv.videoplayer"
    compileSdk = 36  // Required by media_kit/video_player plugin versions
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // The boot animation (assets/video/bootanimation.ts) is opened by
    // MediaPlayer through an AssetFileDescriptor on the legacy boxes, and a
    // COMPRESSED asset has no seekable descriptor — openFd() throws
    // "it is probably compressed". Keep .ts stored, not deflated.
    androidResources {
        noCompress += "ts"
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
            //
            // RK3528/RK3328 boxes are arm64 Cortex-A53. See [isStbRelease] above
            // for why the filter lives here and not in `--target-platform`.
            if (isStbRelease) {
                ndk {
                    abiFilters.clear()
                    abiFilters += setOf("arm64-v8a", "armeabi-v7a")
                }
            }
        }
    }

    // `ndk.abiFilters` above only covers libs this module builds — it does NOT
    // strip prebuilt .so files that arrive inside an AAR, which is exactly where
    // the big one lives (libmpv.so, ~12 MB per ABI, from media_kit_libs_android_
    // video). Excluding them at packaging time is what actually drops the apk
    // from ~113 MB to ~47 MB.
    if (isReleaseBuild) {
        packaging {
            jniLibs {
                // Both ARM ABIs stay: 32-bit devices exist on both lines — STB
                // boxes with a 32-bit userspace, and older Fire TV sticks are
                // armeabi-v7a — and an arm64-only apk fails outright there
                // (INSTALL_FAILED_NO_MATCHING_ABIS). Only the Intel pair goes —
                // no set-top box, Fire TV, or phone we ship to is x86, and it
                // is the single largest chunk (~37 MB).
                excludes += setOf(
                    "**/x86/**",
                    "**/x86_64/**",
                )
            }
        }
    }
}

dependencies {
    // Media3/ExoPlayer for the native SurfaceView player (StbSurfacePlayer.kt),
    // used on the legacy STB decode path. Pinned to the version
    // video_player_android already resolves so there is exactly one Media3 on the
    // classpath — a second, different one shows up as duplicate-class errors.
    implementation("androidx.media3:media3-exoplayer:1.5.1")
    implementation("androidx.media3:media3-exoplayer-hls:1.5.1")
}

flutter {
    source = "../.."
}
