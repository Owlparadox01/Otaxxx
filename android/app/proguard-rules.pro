# Keep Flutter entrypoints and plugin registrant names safe while shrinking.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.BuildConfig { *; }
-dontwarn io.flutter.embedding.**

# Common rules for reflection-heavy AndroidX/Kotlin usage.
-keep class kotlin.Metadata { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlinx.**
-dontwarn org.jetbrains.annotations.**
