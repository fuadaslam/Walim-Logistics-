allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")

    val project = this
    fun applyNamespaceFix() {
        if (project.plugins.hasPlugin("com.android.library") || project.plugins.hasPlugin("com.android.application")) {
            val android = project.extensions.findByName("android")
            if (android != null) {
                try {
                    val getNamespace = android.javaClass.getMethod("getNamespace")
                    if (getNamespace.invoke(android) == null) {
                        val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                        val packageName = project.group.toString().takeIf { it.isNotEmpty() } ?: "dev.isar.isar_flutter_libs"
                        setNamespace.invoke(android, packageName)
                    }
                } catch (e: Exception) {
                    // Method not found or other issue
                }
            }
        }
    }

    fun applyCompileSdkFix() {
        if (project.plugins.hasPlugin("com.android.library") || project.plugins.hasPlugin("com.android.application")) {
            val android = project.extensions.findByName("android")
            if (android != null) {
                try {
                    val getCompileSdkVersion = android.javaClass.getMethod("getCompileSdkVersion")
                    val currentSdk = getCompileSdkVersion.invoke(android) as? Int ?: 0
                    if (currentSdk < 34) {
                        val setCompileSdkVersion = android.javaClass.getMethod("compileSdkVersion", Int::class.java)
                        setCompileSdkVersion.invoke(android, 34)
                    }
                } catch (e: Exception) {
                    // Method not found or other issue
                }
            }
        }
    }

    if (project.state.executed) {
        applyNamespaceFix()
        applyCompileSdkFix()
    } else {
        project.afterEvaluate {
            applyNamespaceFix()
            applyCompileSdkFix()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
