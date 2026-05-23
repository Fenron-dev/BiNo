allprojects {
    repositories {
        google()
        mavenCentral()
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

// JVM-Ziel-Inkonsistenz von receive_sharing_intent wird über gradle.properties
// mit kotlin.jvm.target.validation.mode=warning als Warnung behandelt.

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
