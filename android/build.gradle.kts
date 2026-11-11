plugins {
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.0.21" apply false
}

// Build output goes outside the project folder, so OneDrive does not sync or lock it.
layout.buildDirectory.set(file("${System.getProperty("user.home")}/.homeworkorders-build/root"))
