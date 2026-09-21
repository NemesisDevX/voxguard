import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing is configured externally — android/key.properties
// (gitignored) or VOXGUARD_* environment variables. Credentials never
// enter the repository, and a release build must NEVER silently fall
// back to the debug key: requesting a release artifact without
// credentials fails loudly so a debug-signed binary can never ship
// as "release".
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}
fun signingProperty(name: String): String? =
    keystoreProperties.getProperty(name) ?: System.getenv(name)

val releaseSigningReady = listOf(
    "storeFile", "storePassword", "keyAlias", "keyPassword",
).all { !signingProperty(it).isNullOrBlank() }

android {
    namespace = "com.voxguard.app"
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
        applicationId = "com.voxguard.app"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningReady) {
            create("release") {
                val storePath = signingProperty("storeFile")!!
                val file = File(storePath)
                storeFile = if (file.isAbsolute) file
                    else rootProject.file(storePath)
                storePassword = signingProperty("storePassword")
                keyAlias = signingProperty("keyAlias")
                keyPassword = signingProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (releaseSigningReady) {
                signingConfig = signingConfigs.getByName("release")
            }
            // When credentials are absent the release buildType has
            // no signing config at all — the task-graph guard below
            // refuses the build before an unsigned/debug artifact
            // could be produced.
        }
    }
}

// Fail loudly only when a release task is actually requested — debug
// builds, tests and `flutter run` never touch this check.
gradle.taskGraph.whenReady {
    val wantsRelease = allTasks.any {
        it.path.contains("release", ignoreCase = true)
    }
    if (wantsRelease && !releaseSigningReady) {
        throw GradleException(
            "BLOCKED_EXTERNAL — release keystore required. Provide " +
                "android/key.properties (storeFile, storePassword, " +
                "keyAlias, keyPassword) or the matching VOXGUARD_* " +
                "environment variables. See docs/FINAL_RELEASE_STATUS.md."
        )
    }
}

flutter {
    source = "../.."
}
