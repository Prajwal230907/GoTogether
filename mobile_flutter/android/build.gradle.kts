allprojects {
    repositories {
        google()
        mavenCentral()
    }
    configurations.all {
        resolutionStrategy {
            force("androidx.activity:activity:1.9.3")
            force("androidx.activity:activity-ktx:1.9.3")
            // In case core-ktx was also upgraded
            force("androidx.core:core-ktx:1.13.1")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

rootProject.layout.buildDirectory.set(rootProject.file("../build"))

subprojects {
    project.layout.buildDirectory.set(rootProject.layout.buildDirectory.dir(project.name))
    project.evaluationDependsOn(":app")

    if (project.name != "app") {
        project.afterEvaluate {
            val androidExt = project.extensions.findByName("android")
            if (androidExt != null) {
                try {
                    androidExt.javaClass.getMethod("setCompileSdk", Int::class.javaPrimitiveType).invoke(androidExt, 34)
                } catch (e: Exception) {
                    try {
                        androidExt.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType).invoke(androidExt, 34)
                    } catch (e2: Exception) {}
                }
            }
        }
    }
}
