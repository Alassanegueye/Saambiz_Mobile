# Règles R8/ProGuard — Fait Maison
# La majorité du code métier est en Dart (compilé en natif ARM, non affecté par R8).
# Ces règles ne concernent que la partie Android/Kotlin + les plugins natifs.

# Flutter : classes du moteur et de l'embedding, ne jamais les supprimer/obfusquer.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Google Play Core (Split Install / Deferred Components) — R8 référence ces classes
# même si l'app ne fait pas de livraison différée. On évite l'échec de build lié
# aux classes manquantes plutôt que d'ajouter la dépendance play-core inutile.
-dontwarn com.google.android.play.core.**

# flutter_secure_storage (Android Keystore / AndroidX Security Crypto)
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**

# Firebase (si ajouté ultérieurement pour les push FCM) — conservation par précaution
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Kotlin metadata / coroutines (utilisés par plusieurs plugins Flutter)
-dontwarn kotlinx.coroutines.**
-keepattributes Signature,InnerClasses,EnclosingMethod,*Annotation*
