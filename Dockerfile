FROM jomifred/jacamo:1.0

# Install necessary tools
RUN apk update && \
    apk add --no-cache wget unzip curl

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Make gradlew executable
RUN chmod +x ./gradlew

# Expose all necessary ports
# 8080 - JaCaMo-Web REST API & Dashboard
# 3271 - Moise HTTP Server
# 3272 - Jason HTTP Server  
# 3273 - CArtAgO HTTP Server
EXPOSE 8080 3271 3272 3273

# Run the JaCaMo application
CMD ["./gradlew", "run"]
