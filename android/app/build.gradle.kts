plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.malekw96.homeworkorders"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.malekw96.homeworkorders"
        minSdk = 29
        targetSdk = 35
        // Keep versionName in step with APP_VERSION in home-work-orders.html
        // (scripts/sync-web.sh refuses to run if they differ). Raise versionCode
        // by one for every new APK so Android accepts it as an update.
        versionCode = 1
        versionName = "1.0.0.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.webkit:webkit:1.12.1")
}
