# --- Build stage: compila com o Maven wrapper (sem Maven instalado no host) ---
FROM eclipse-temurin:21-jdk AS build
WORKDIR /app
# Copia primeiro o wrapper + pom para cachear as dependências entre builds.
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN ./mvnw -q -DskipTests dependency:go-offline
COPY src ./src
RUN ./mvnw -q -DskipTests package

# --- Runtime stage: só o JRE + o jar ---
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
