# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Supabase / GoTrue / Realtime
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# OkHttp (used by some plugins)
-dontwarn okhttp3.**
-dontwarn okio.**

# Gson (if used by any plugin)
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Keep annotations
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes Exceptions

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }
