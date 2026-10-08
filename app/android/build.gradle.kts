allprojects {
    repositories {
        google()
        mavenCentral()
        // image_cropper pulls in com.github.Yalantis:ucrop, which is only
        // published on JitPack.
        maven { url = uri("https://jitpack.io") }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Plugin modules disagree about which SDK to compile against — livekit_client
// says 34, flutter_webrtc's AAR needs 36, permission_handler_android needs 37
// for ACCESS_LOCAL_NETWORK — so they are all pinned to the highest, which they
// are backward compatible with. This must track the app's compileSdk above:
// pinning lower is what makes a plugin that asks for 37 fail to compile, even
// when the app itself is on 37. API 37 ships only as minor releases
// (android-37.0/37.1), hence the minor alongside it. The `state.executed` guard
// covers subprojects the eager `evaluationDependsOn` above already evaluated.
subprojects {
    fun forceCompileSdk() {
        (extensions.findByName("android") as? com.android.build.api.dsl.LibraryExtension)
            ?.let {
                it.compileSdk = 37
                it.compileSdkMinor = 0
            }
    }
    if (state.executed) forceCompileSdk() else afterEvaluate { forceCompileSdk() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
