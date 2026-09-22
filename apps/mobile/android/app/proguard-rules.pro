# Flutter / plugins reached through JNI or reflection must survive R8.
-keep class io.flutter.** { *; }
-keep class com.alexmercerind.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn io.flutter.embedding.**
-dontwarn com.google.android.play.core.**
