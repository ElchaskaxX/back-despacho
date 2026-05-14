# ================================
# STAGE 1: Build con Maven
# ================================
FROM maven:3.9-eclipse-temurin-17-alpine AS builder

WORKDIR /app

# Copiar pom.xml primero para cachear dependencias
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copiar código fuente
COPY src ./src

# Compilar y empaquetar (sin tests para el build de imagen)
RUN mvn clean package -DskipTests -B && \
    # Limpiar cache de Maven para reducir tamaño
    rm -rf /root/.m2

# ================================
# STAGE 2: Runtime mínimo
# ================================
FROM eclipse-temurin:17-jre-alpine AS production

# Usuario no root (mínimo privilegio)
RUN addgroup -S springgroup && adduser -S springuser -G springgroup

WORKDIR /app

# Copiar solo el JAR generado
COPY --from=builder /app/target/*.jar app.jar

# Dar permisos al usuario no root
RUN chown springuser:springgroup app.jar

USER springuser

EXPOSE 8081

HEALTHCHECK --interval=30s --timeout=10s --start-period=45s --retries=3 \
  CMD wget -qO- http://localhost:8081/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "-Djava.security.egd=file:/dev/./urandom", "app.jar"]
