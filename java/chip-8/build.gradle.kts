plugins {
    id("java")
}

group = "dev.daniel-taylor.emulated-freedom"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
}

dependencies {
    implementation("com.google.inject:guice:7.0.0")
    testImplementation(platform("org.junit:junit-bom:5.11.4"))
    testImplementation("org.junit.jupiter:junit-jupiter")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

tasks.test {
    useJUnitPlatform()
}

tasks.jar {
    manifest {
        attributes("Main-Class" to "dev.daniel.taylor.emulators.chip8.Emulator")
    }
    from(provider {
        configurations.runtimeClasspath.get().map { if (it.isDirectory) it else zipTree(it) }
    })
    duplicatesStrategy = DuplicatesStrategy.EXCLUDE
}
