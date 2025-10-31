# ===== STAGE 1: Build =====
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

COPY pom.xml .
COPY src ./src

# Baue und liste auf, damit wir sehen, was im target/ liegt
RUN mvn -B -DskipTests=false package && ls -la target


# ===== STAGE 2: Runtime =====
FROM eclipse-temurin:17-jre
WORKDIR /app

# Kopiere das erzeugte JAR aus target nach /app/app.jar
COPY --from=build /app/target/*.jar /app/app.jar

# Wenn kein Main-Manifest vorhanden ist: starte per FQCN - fully qualified name (deine Main-Klasse)
ENTRYPOINT ["java","-cp","/app/app.jar","com.example.hello.App"]

# Falls deine App ein HTTP-Server ist, öffne den Port:
# EXPOSE 8080