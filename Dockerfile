FROM jomifred/jacamo:1.0

# Install necessary tools
RUN apk update && \
    apk add --no-cache wget unzip curl

# Set working directory
WORKDIR /app

# ========== GRADLE CACHING OPTIMIZATION ==========
# Copy only gradle wrapper files first (for better Docker layer caching)
COPY gradlew .
COPY gradle/ gradle/

# Make gradlew executable and download Gradle (cached layer)
RUN chmod +x ./gradlew && \
    ./gradlew --version

# Copy build.gradle to download dependencies (cached layer)
COPY build.gradle .
COPY settings.gradle* ./
RUN ./gradlew dependencies --no-daemon || true

# ========== PROJECT FILES ==========
# Now copy the rest of the project files
COPY . .

# Expose all necessary ports
# 8080 - JaCaMo-Web REST API & Dashboard
# 3271 - Moise HTTP Server
# 3272 - Jason HTTP Server  
# 3273 - CArtAgO HTTP Server
EXPOSE 8080 3271 3272 3273

# Run the JaCaMo application
CMD ["./gradlew", "run", "--no-daemon"]
