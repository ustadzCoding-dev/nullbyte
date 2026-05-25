# Hive — keep generated adapters and model classes
-keep class * extends com.google.gson.TypeAdapterFactory
-keep class * extends com.google.gson.TypeAdapter
-keep class com.nullbytegames.nullbyte.** { *; }
-keep class hive.** { *; }

# Flame / FlameAudio — keep audioplayers and asset cache
-keep class com.djammr.flame_audio.** { *; }
-keep class audioplayers.** { *; }
-keep class dev.flame.** { *; }

# Riverpod — keep provider classes
-keep class * extends java.lang.reflect.** { *; }

# Flutter engine
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# General — prevent stripping of reflection-used classes
-dontwarn javax.annotation.**
-dontwarn android.support.annotation.**
