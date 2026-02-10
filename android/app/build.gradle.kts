import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.dhvanicast.radio"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.dhvanicast.radio"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 5
        versionName = "1.0.2"
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            // Only configure signing if key.properties exists with all required values
            if (keystorePropertiesFile.exists()) {
                val keyAliasValue = keystoreProperties["keyAlias"]
                val keyPasswordValue = keystoreProperties["keyPassword"]
                val storeFileValue = keystoreProperties["storeFile"]
                val storePasswordValue = keystoreProperties["storePassword"]

                if (keyAliasValue != null && keyPasswordValue != null && storeFileValue != null && storePasswordValue != null) {
                    keyAlias = keyAliasValue as String
                    keyPassword = keyPasswordValue as String
                    storeFile = file(storeFileValue as String)
                    storePassword = storePasswordValue as String
                }
            }
        }
    }

    buildTypes {
        release {
            // Use release signing config if keystore configured, otherwise use debug
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Disable minification to prevent crashes
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("androidx.window:window:1.0.0")
    implementation("androidx.window:window-java:1.0.0")
}

flutter {
    source = "../.."
}
