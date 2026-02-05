import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load signing config from android/key.properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    throw GradleException("Missing key.properties at: ${keystorePropertiesFile.absolutePath}")
}

android {
    namespace = "com.raderbrandon.finishit"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    defaultConfig {
        applicationId = "com.raderbrandon.finishit"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties["storeFile"] as String?
                ?: throw GradleException("key.properties missing storeFile")
            val storePassword = keystoreProperties["storePassword"] as String?
                ?: throw GradleException("key.properties missing storePassword")
            val keyAlias = keystoreProperties["keyAlias"] as String?
                ?: throw GradleException("key.properties missing keyAlias")
            val keyPassword = keystoreProperties["keyPassword"] as String?
                ?: throw GradleException("key.properties missing keyPassword")

            this.storeFile = file(storeFilePath)
            this.storePassword = storePassword
            this.keyAlias = keyAlias
            this.keyPassword = keyPassword
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }

        // Keep debug as default debug signing
        getByName("debug") {
            // no changes needed
        }
    }
}

flutter {
    source = "../.."
}
