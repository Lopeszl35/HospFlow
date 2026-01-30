plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.protocolo_hospitalar"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.protocolo_hospitalar"
        
        // O OCR (ML Kit) exige no mínimo API 21
        minSdk = 21
        
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // CRÍTICO: Define explicitamente que usa Embedding V2
        manifestPlaceholders["flutterEmbedding"] = "2"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    
    // IMPORTANTE: Força o build a reconhecer V2
    buildFeatures {
        buildConfig = true
    }
}

flutter {
    source = "../.."
}
