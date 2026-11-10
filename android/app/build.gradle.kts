import java.util.Properties
import java.io.FileInputStream
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Notifications push (Firebase Cloud Messaging). Le plugin Google Services
// lit android/app/google-services.json, à télécharger depuis la console
// Firebase (application Android « com.saambiz.app »). Tant que le fichier
// manque, on ne l'applique pas : l'application se construit et tourne, sans
// notifications push.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

// Chargement des identifiants de signature release depuis android/key.properties
// (ce fichier ne doit PAS être versionné — voir .gitignore). Si absent, on retombe
// sur les clés debug pour que `flutter run` continue de fonctionner.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.saambiz.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Requis par flutter_local_notifications (API java.time via desugaring).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    defaultConfig {
        // Identité de l'application sur le Play Store. Définitive dès la
        // première mise en ligne : Google n'autorise aucun changement ensuite.
        //
        // Elle valait « com.faitmaison.app » — l'ancien nom du projet, hérité
        // de fait_maison — et le namespace restait sur « com.example.fait_maison ».
        // Corrigé avant publication, seul moment où c'était encore possible.
        applicationId = "com.saambiz.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Signature release si key.properties présent, sinon repli sur debug
            // (permet de continuer à lancer `flutter run` sans keystore).
            signingConfig = if (keystorePropertiesFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")

            // Shrink + obfuscation R8 pour la release : réduit la taille de l'AAB
            // et complique la rétro-ingénierie (règles de conservation dans proguard-rules.pro).
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Requis par flutter_local_notifications.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// Kotlin 2.2 : `kotlinOptions` dans le bloc android n'est plus accepté.
kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_11)
    }
}
