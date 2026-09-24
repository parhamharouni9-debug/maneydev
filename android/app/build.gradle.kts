import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use(keystoreProperties::load)
}

val releaseKeyAlias = keystoreProperties.getProperty("keyAlias")?.takeIf(String::isNotBlank)
val releaseKeyPassword = keystoreProperties.getProperty("keyPassword")?.takeIf(String::isNotBlank)
val releaseStorePath = keystoreProperties.getProperty("storeFile")?.takeIf(String::isNotBlank)
val releaseStorePassword = keystoreProperties.getProperty("storePassword")?.takeIf(String::isNotBlank)
val releaseStoreFile = releaseStorePath?.let(::file)
val releaseSigningConfigured =
    releaseKeyAlias != null &&
        releaseKeyPassword != null &&
        releaseStorePassword != null &&
        releaseStoreFile?.isFile == true

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.parham.pool_man"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.parham.pool_man"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningConfigured) {
            create("release") {
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                storeFile = releaseStoreFile
                storePassword = releaseStorePassword
            }
        }
    }

    buildTypes {
        release {
            signingConfigs.findByName("release")?.let { signingConfig = it }
        }
    }
}

gradle.taskGraph.whenReady {
    val appReleaseRequested = allTasks.any { task ->
        task.path.startsWith(":app:") && task.name.contains("Release", ignoreCase = true)
    }
    if (appReleaseRequested && !releaseSigningConfigured) {
        throw GradleException(
            "Release signing is not configured. Add android/key.properties with " +
                "keyAlias, keyPassword, storeFile, and storePassword, and ensure the keystore file exists.",
        )
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
