plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // Atualizado para o plugin moderno
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // 1. CORREÇÃO DE NOME
    namespace = "com.example.hospflow"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // 2. ATUALIZAÇÃO PARA JAVA 17 (Necessário para Gradle 8+)
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // 1. CORREÇÃO DE NOME
        applicationId = "com.example.hospflow"
        
        // OCR exige minSdk 21
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 3. CORREÇÃO CRÍTICA PARA O ERRO DO FLUTLAB/LINT
    // Isso ignora o erro do byte-buddy e permite gerar o APK
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    buildTypes {
        release {
            // Usa a chave de debug para facilitar o build no FlutLab sem configurar keystore
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}