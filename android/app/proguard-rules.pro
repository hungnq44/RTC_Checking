# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Notification Channel & Receiver
-keep class android.app.NotificationChannel { *; }
-keep class android.app.NotificationManager { *; }
-keep class android.content.BroadcastReceiver { *; }

# Google Play Core (ignore missing)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Keep notification sound resource
-keep class **.R$raw { *; }

# Reflection / Runtime
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes SourceFile,LineNumberTable

# ==========================================
# MAPBOX MAPS FLUTTER - CRITICAL RULES
# ==========================================

# Keep ALL Mapbox classes - DO NOT MINIFY OR OBFUSCATE
-keep class com.mapbox.** { *; }
-dontwarn com.mapbox.**
-dontnote com.mapbox.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Keep Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep method channel classes
-keep class com.example.rtc_checking.AlarmServicePlugin { *; }
-keep class com.example.rtc_checking.AlarmForegroundService { *; }
-keep class com.example.rtc_checking.MainActivity { *; }

# ==========================================
# GOOGLE PLAY SERVICES LOCATION
# ==========================================
-keep class com.google.android.gms.location.** { *; }
-dontwarn com.google.android.gms.location.**

# ==========================================
# GEOLOCATOR
# ==========================================
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

# ==========================================
# CRITICAL - Disable optimization for mapbox
# ==========================================
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-allowaccessmodification
-repackageclasses
