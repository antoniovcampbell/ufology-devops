# Builder stage with Maven and Java 21
FROM maven:3.9.9-eclipse-temurin-21 AS builder

WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Final stage with Alpine-based Amazon Corretto 21
FROM amazoncorretto:21-alpine

WORKDIR /app

# Install wget for healthcheck
RUN apk add --no-cache wget

# Create non-root user (Alpine syntax)
RUN addgroup -S ufology && adduser -S ufology -G ufology

COPY --from=builder /app/target/*.jar app.jar
RUN chown -R ufology:ufology /app
USER ufology

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]