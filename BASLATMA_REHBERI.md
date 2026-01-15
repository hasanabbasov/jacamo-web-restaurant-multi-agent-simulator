# JaCaMo Marketplace - Hızlı Başlangıç

## ✅ Kurulum Tamamlandı!

Projeniz JaCaMo-Web IDE desteği ile çalışmaya hazır.

## 🚀 Projeyi Çalıştırma

### Seçenek 1: Docker Compose (Önerilen)

```bash
# Proje dizinine gidin
cd /Users/hasanabasov/Desktop/Desktop_File/Ege/Last/jacamo-web-demo-marketplace-master

# Uygulamayı başlatın
docker-compose up --build
```

### Seçenek 2: Manuel Docker

```bash
# Image zaten build edildi
docker run --rm \
    -v "$(pwd)":/app \
    -p 2181:2181 \
    -p 8080:8080 \
    -p 3271:3271 \
    -p 3272:3272 \
    -p 3273:3273 \
    jacamo-marketplace:latest
```

### Seçenek 3: Lokal Gradle

```bash
./gradlew run
```

## 🌐 Erişim Portları

Uygulama çalıştıktan sonra:

- **Port 2181**: http://localhost:2181 - JaCaMo-Web IDE
- **Port 8080**: http://localhost:8080 - REST API
- **Port 3271**: http://localhost:3271 - Moise API (Organizations)
- **Port 3272**: http://localhost:3272 - Jason API (Agents)
- **Port 3273**: http://localhost:3273 - CArtAgO API (Artifacts)

## 🧪 Test Etme

```bash
# Agent'ları listele
curl http://localhost:3272/agents

# Workspace'leri görüntüle
curl http://localhost:3273/workspaces

# Organizasyonları görüntüle
curl http://localhost:3271/organisations
```

## 📝 Yapılan Değişiklikler

1. ✅ **Dockerfile** - Alpine Linux package manager desteği ile özel image
2. ✅ **docker-compose.yml** - Tüm portlar map edilmiş
3. ✅ **marketplace.jcm** - Web platform aktif (zaten aktifti)
4. ✅ **build.gradle** - jacamo-web dependency (zaten vardı)

## 🔧 Sorun Giderme

### Port 2181 erişilemiyor

1. Container'ı kontrol edin:
   ```bash
   docker ps
   ```

2. Log'ları kontrol edin:
   ```bash
   docker-compose logs
   ```

3. Port çakışması kontrol edin:
   ```bash
   lsof -i :2181
   ```

### Gradle Build Hatası

Eğer Docker ile sorun yaşarsanız, lokal Gradle kullanın:
```bash
./gradlew clean run
```

## 📚 Detaylı Dokümantasyon

- **DOCKER_SETUP.md** - Kapsamlı Docker kurulum rehberi
- **AGENTS.md** - JaCaMo platform detayları
- **proje_sunum.md** - Türkçe proje sunumu

Başarılar! 🎉
