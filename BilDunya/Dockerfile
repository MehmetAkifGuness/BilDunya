FROM maven:3.9-eclipse-temurin-21-alpine AS builder

WORKDIR /app

# Copy pom.xml and source
COPY pom.xml /app/
COPY src /app/src

# Build the application
RUN mvn clean package -DskipTests

FROM eclipse-temurin:21-jdk-alpine

RUN addgroup -S spring && adduser -S spring -G spring

WORKDIR /app

# Copy JAR from builder
COPY --from=builder /app/target/*.jar app.jar

USER spring:spring

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]