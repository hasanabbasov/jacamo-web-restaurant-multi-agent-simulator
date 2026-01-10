# 🔗 simulation.html, Nginx ve JaCaMo İletişim Mimarisi

Bu projede 3 katmanlı bir iletişim yapısı vardır:

```
┌─────────────────────┐
│   BROWSER (Client)  │
│   simulation.html   │
│   JavaScript        │
└──────────┬──────────┘
           │ HTTP Requests
           │ (localhost:8080)
           ▼
┌─────────────────────┐
│      NGINX          │
│   (Reverse Proxy)   │
│   Port: 8080        │
└──────────┬──────────┘
           │ Proxy Pass
           │ (http://jacamo:8080)
           ▼
┌─────────────────────┐
│     JaCaMo-Web      │
│    REST API         │
│    Port: 8080       │
└─────────────────────┘
```

---

## 1️⃣ simulation.html → Nginx

`simulation.html` kullanıcının tarayıcısında çalışan bir web sayfasıdır. İçindeki JavaScript kodu, kullanıcı etkileşimlerini (örn. sipariş butonu tıklaması) HTTP isteklerine dönüştürür. Bu istekler relative path kullandığından, browser otomatik olarak aynı origin'e (localhost:8080) yönlendirir.

**Nerede:** `simulation.html` içindeki JavaScript kodu

```javascript
const API_BASE = '';  // Relative path (same-origin)

// Sipariş gönderme
await fetch(API_BASE + '/agents/waiter/inbox', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
        performative: 'achieve',
        sender: 'customer1',
        receiver: 'waiter',
        msgId: 'order_' + Date.now(),
        content: 'takeOrder(customer1, pizza)'
    })
});

// Agent listesi alma
await fetch(API_BASE + '/agents');

// Artifact durumu (polling)
await fetch(API_BASE + '/workspaces/diningRoom/artifacts/orderBoard');
```

**Ne oluyor:**
- Browser `http://localhost:8080/agents/waiter/inbox` adresine istek atar
- Bu istek Nginx'e gider (Port 8080)

---

## 2️⃣ Nginx → JaCaMo

Nginx bir reverse proxy görevi görür. Gelen isteklerin URL'sine bakarak onları doğru hedefe yönlendirir. `/simulation.html` için kendi içindeki dosyayı serve ederken, `/agents` veya `/workspaces` ile başlayan istekleri JaCaMo container'ına proxy eder. Bu sayede browser tek bir port (8080) üzerinden hem statik dosyalara hem de API'ye erişebilir.

**Nerede:** `nginx.conf`

```nginx
server {
    listen 80;
    
    # Statik dosya: simulation.html
    location = /simulation.html {
        root /usr/share/nginx/html;
        try_files $uri =404;
    }
    
    # API istekleri → JaCaMo'ya proxy
    location /agents {
        proxy_pass http://jacamo:8080/agents;
        proxy_http_version 1.1;
        
        # CORS headers
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
    }
    
    location /workspaces {
        proxy_pass http://jacamo:8080/workspaces;
    }
    
    # Diğer tüm istekler → JaCaMo-Web UI
    location / {
        proxy_pass http://jacamo:8080;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

**Ne oluyor:**
- `/simulation.html` → Nginx statik dosya olarak serve eder
- `/agents/*` → JaCaMo REST API'ye yönlendirir
- `/workspaces/*` → JaCaMo Environment API'ye yönlendirir
- `/*` (diğer) → JaCaMo-Web UI'a yönlendirir

---

## 3️⃣ JaCaMo REST API

JaCaMo-Web, JaCaMo platformunun üzerine inşa edilmiş bir web katmanıdır. REST API endpoint'leri aracılığıyla agent'lara mesaj göndermek, durumlarını sorgulamak ve artifact'leri izlemek mümkündür. `/agents/{name}/inbox` endpoint'ine POST yapıldığında, mesaj ilgili agent'ın posta kutusuna eklenir ve agent bunu işleyebilir.

**Port:** 8080 (Docker container içinde)

**Önemli Endpoint'ler:**

| Endpoint | Method | Açıklama |
|----------|--------|----------|
| `/agents` | GET | Tüm agent'ları listele |
| `/agents/{name}` | GET | Agent detayları |
| `/agents/{name}/inbox` | POST | Agent'a mesaj gönder |
| `/workspaces` | GET | Workspace listesi |
| `/workspaces/{ws}/artifacts/{art}` | GET | Artifact durumu |

---

## 📦 Docker Compose Bağlantısı

Docker Compose, birden fazla container'ı tek bir yapılandırma dosyasıyla yönetmeyi sağlar. Bu projede JaCaMo ve Nginx iki ayrı container olarak çalışır. Docker otomatik olarak bir bridge network oluşturur ve container'lar birbirlerine isimleriyle (örn. `jacamo`) erişebilir. `expose` komutu portu sadece Docker network içinde açarken, `ports` komutu dış dünyaya açar.

```yaml
services:
  jacamo:
    build: .
    container_name: jacamo-web-demo-restaurant-master
    expose:
      - "8080"  # Sadece Docker network içinde erişilebilir
    
  nginx:
    image: nginx:alpine
    container_name: jacamo-web-demo-restaurant-nginx
    ports:
      - "8080:80"  # Dış dünya:8080 → Container:80
    volumes:
      - ./simulation.html:/usr/share/nginx/html/simulation.html
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - jacamo
```

**Docker Network:**
- Nginx `http://jacamo:8080` üzerinden JaCaMo'ya erişir
- `jacamo` ismi Docker DNS tarafından çözümlenir (aynı network'teki container)
- JaCaMo portu dış dünyaya kapalı, sadece Nginx erişebilir

---

## 🔄 Tam Akış Örneği: Pizza Siparişi

Aşağıdaki akış, kullanıcının web arayüzünden pizza sipariş etmesinden yemeğin hazırlanıp servis edilmesine kadar tüm süreci gösterir. Her adımda hangi bileşenin çalıştığı ve veri akışının nasıl gerçekleştiği açıkça görülebilir.

```
1. Kullanıcı "Siparişi Gönder" butonuna tıklar
   ↓
2. JavaScript: fetch('/agents/waiter/inbox', {...pizza...})
   ↓
3. Browser → Nginx:8080 → POST /agents/waiter/inbox
   ↓
4. Nginx → JaCaMo:8080 → POST /agents/waiter/inbox (proxy_pass)
   ↓
5. JaCaMo: waiter agent'ın inbox'ına mesaj koyar
   ↓
6. waiter.asl: +!takeOrder(customer1, pizza) planı tetiklenir
   ↓
7. waiter → cook: .send(cook, achieve, prepareFood(...))
   ↓
8. cook.asl: 15 saniye bekler, .send(waiter, tell, foodReady(...))
   ↓
9. simulation.html: pollJaCaMoStatus() → OrderBoard artifact'i poll eder
   ↓
10. UI güncellenir: Bekleyen → Pişiyor → Tamamlandı
```

---

## 🔑 Neden Nginx Gerekli?

Nginx olmadan bu sistem çalışmaz çünkü tarayıcılar güvenlik sebebiyle farklı port veya origin'lere doğrudan istek atmayı engeller (CORS politikası). Nginx, tüm istekleri tek bir origin üzerinden yöneterek bu sorunu çözer.

| Sebep | Açıklama |
|-------|----------|
| **CORS Çözümü** | Browser farklı origin'lere istek atarken güvenlik hatası verir. Nginx same-origin proxy sağlar. |
| **Statik Dosya** | `simulation.html` JaCaMo'nun parçası değil, Nginx serve eder. |
| **Port Birleştirme** | Tek port (8080) üzerinden hem HTML hem API erişimi. |
| **Güvenlik** | JaCaMo iç portu dış dünyaya kapalı kalır. |
