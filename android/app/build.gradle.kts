plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

layout.buildDirectory.set(file("${System.getProperty("user.home")}/.homeworkorders-build/app"))

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
        versionCode = 19
        versionName = "2.6.0.0"
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

// After a debug build, also copy the APK into the project's apk/ folder.
val copyDebugApk by tasks.registering(Copy::class) {
    from(layout.buildDirectory.dir("outputs/apk/debug")) { include("*.apk") }
    into(rootProject.layout.projectDirectory.dir("apk"))
    rename { "HomeWorkOrders-v${android.defaultConfig.versionName}.apk" }
}
afterEvaluate {
    tasks.named("assembleDebug") { finalizedBy(copyDebugApk) }
}

dependencies {
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.webkit:webkit:1.12.1")
}
