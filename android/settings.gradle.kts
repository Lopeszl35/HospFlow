pluginManagement {
    val flutterSdkPath = try {
        val properties = java.util.Properties()
        val file = java.io.File("local.properties")
        if (file.exists()) {
            properties.load(java.io.FileInputStream(file))
            properties.getProperty("flutter.sdk")
        } else {
            null
        }
    } catch (e: Exception) {
        null
    }

    // --- A CORREÇÃO ESTÁ AQUI: ---
    if (flutterSdkPath != null) {
        includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
    }
    // -----------------------------

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    // Agora ele vai encontrar este plugin porque incluímos o path acima
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.2.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.0" apply false
}

include(":app")