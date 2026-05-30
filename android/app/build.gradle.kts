import org.gradle.api.GradleException
import java.io.FileInputStream
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun decodeDartDefines(): Map<String, String> {
    val encodedDefines = project.findProperty("dart-defines") as? String ?: return emptyMap()
    return encodedDefines
        .split(",")
        .filter { it.isNotBlank() }
        .mapNotNull { encoded ->
            runCatching {
                String(Base64.getDecoder().decode(encoded), Charsets.UTF_8)
            }.getOrNull()
        }
        .mapNotNull { entry ->
            val separatorIndex = entry.indexOf("=")
            if (separatorIndex <= 0) {
                null
            } else {
                entry.substring(0, separatorIndex) to entry.substring(separatorIndex + 1)
            }
        }
        .toMap()
}

fun loadEnvConfig(fileName: String): Map<String, String> {
    val envFile = rootProject.file("../$fileName")
    if (!envFile.exists()) return emptyMap()

    return envFile
        .readLines()
        .mapNotNull { rawLine ->
            val line = rawLine.trim()
            if (line.isEmpty() || line.startsWith("#") || !line.contains("=")) {
                null
            } else {
                val key = line.substringBefore("=").trim()
                val value = line
                    .substringAfter("=")
                    .trim()
                    .trim('"', '\'')
                key to value
            }
        }
        .toMap()
}

val dartDefines = decodeDartDefines()
val selectedEnvFile =
    (project.findProperty("ENV") as? String)?.takeIf { it.isNotBlank() }
        ?: dartDefines["ENV"]?.takeIf { it.isNotBlank() }
        ?: System.getenv("ENV")?.takeIf { it.isNotBlank() }
        ?: ".env"
val envConfig = loadEnvConfig(selectedEnvFile)

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val admobAppEnv = envConfig["APP_ENV"]?.lowercase() ?: "dev"
val admobAppIdAndroid = envConfig["ADMOB_APP_ID_ANDROID"]
    ?: throw GradleException(
        "Missing ADMOB_APP_ID_ANDROID in $selectedEnvFile. " +
            "APP_ENV=$admobAppEnv will not fall back to a test AdMob app ID."
    )

android {
    namespace = "com.mindcolorpour"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mindcolorpour"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["admobAppIdAndroid"] = admobAppIdAndroid
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (keystorePropertiesFile.exists()) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
