# JaCaMo Marketplace - Quick Start

## ✅ Installation Complete!

Your project is ready to run with JaCaMo-Web IDE support.

## 🚀 Running the Project

### Option 1: Docker Compose (Recommended)

```bash
# Navigate to the project directory
cd /Users/hasanabasov/Desktop/Desktop_File/Ege/Last/jacamo-web-demo-marketplace-master

# Start the application
docker-compose up --build
```

### Option 2: Manual Docker

```bash
# Image is already built
docker run --rm \
    -v "$(pwd)":/app \
    -p 2181:2181 \
    -p 8080:8080 \
    -p 3271:3271 \
    -p 3272:3272 \
    -p 3273:3273 \
    jacamo-marketplace:latest
```

### Option 3: Local Gradle

```bash
./gradlew run
```

## 🌐 Access Ports

After the application starts:

- **Port 2181**: http://localhost:2181 - JaCaMo-Web IDE
- **Port 8080**: http://localhost:8080 - REST API
- **Port 3271**: http://localhost:3271 - Moise API (Organizations)
- **Port 3272**: http://localhost:3272 - Jason API (Agents)
- **Port 3273**: http://localhost:3273 - CArtAgO API (Artifacts)

## 🧪 Testing

```bash
# List agents
curl http://localhost:3272/agents

# View workspaces
curl http://localhost:3273/workspaces

# View organizations
curl http://localhost:3271/organisations
```

## 📝 Changes Made

1. ✅ **Dockerfile** - Custom image with Alpine Linux package manager support
2. ✅ **docker-compose.yml** - All ports mapped
3. ✅ **marketplace.jcm** - Web platform active (was already active)
4. ✅ **build.gradle** - jacamo-web dependency (was already present)

## 🔧 Troubleshooting

### Port 2181 not accessible

1. Check the container:
   ```bash
   docker ps
   ```

2. Check the logs:
   ```bash
   docker-compose logs
   ```

3. Check for port conflicts:
   ```bash
   lsof -i :2181
   ```

### Gradle Build Error

If you have issues with Docker, use local Gradle:
```bash
./gradlew clean run
```

## 📚 Detailed Documentation

- **DOCKER_SETUP.md** - Comprehensive Docker setup guide
- **AGENTS.md** - JaCaMo platform details
- **PRESENTATION_SCRIPT.md** - Project presentation script

Good luck! 🎉
