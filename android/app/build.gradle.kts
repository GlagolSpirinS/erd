plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.erd"
    compileSdk = flutter.compileSdkVersion.toInt()
    ndkVersion = flutter.ndkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.erd"
        minSdk = flutter.minSdkVersion.toInt()
        targetSdk = flutter.targetSdkVersion.toInt()
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    packaging {
        resources {
            // Правильный синтаксис для pickFirst в Kotlin DSL
            pickFirsts.add("lib/x86/libsqlite3.so")
            pickFirsts.add("lib/x86_64/libsqlite3.so")
            pickFirsts.add("lib/armeabi-v7a/libsqlite3.so")
            pickFirsts.add("lib/arm64-v8a/libsqlite3.so")
        }
    }
}

flutter {
    source = "../.."
}