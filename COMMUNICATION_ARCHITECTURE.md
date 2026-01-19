# 🔗 simulation.html, Nginx and JaCaMo Communication Architecture

This project has a 3-layer communication structure:

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

`simulation.html` is a web page that runs in the user's browser. The JavaScript code inside converts user interactions (e.g., order button clicks) into HTTP requests. Since these requests use relative paths, the browser automatically redirects to the same origin (localhost:8080).

**Location:** JavaScript code inside `simulation.html`

```javascript
const API_BASE = '';  // Relative path (same-origin)

// Sending an order
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

// Getting agent list
await fetch(API_BASE + '/agents');

// Artifact status (polling)
await fetch(API_BASE + '/workspaces/diningRoom/artifacts/orderBoard');
```

**What happens:**
- Browser sends request to `http://localhost:8080/agents/waiter/inbox`
- This request goes to Nginx (Port 8080)

---

## 2️⃣ Nginx → JaCaMo

Nginx acts as a reverse proxy. It looks at the URL of incoming requests and routes them to the correct destination. For `/simulation.html`, it serves the file from its own content, while requests starting with `/agents` or `/workspaces` are proxied to the JaCaMo container. This way, the browser can access both static files and the API through a single port (8080).

**Location:** `nginx.conf`

```nginx
server {
    listen 80;
    
    # Static file: simulation.html
    location = /simulation.html {
        root /usr/share/nginx/html;
        try_files $uri =404;
    }
    
    # API requests → Proxy to JaCaMo
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
    
    # All other requests → JaCaMo-Web UI
    location / {
        proxy_pass http://jacamo:8080;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

**What happens:**
- `/simulation.html` → Nginx serves as static file
- `/agents/*` → Routes to JaCaMo REST API
- `/workspaces/*` → Routes to JaCaMo Environment API
- `/*` (others) → Routes to JaCaMo-Web UI

---

## 3️⃣ JaCaMo REST API

JaCaMo-Web is a web layer built on top of the JaCaMo platform. Through REST API endpoints, it's possible to send messages to agents, query their status, and monitor artifacts. When a POST is made to the `/agents/{name}/inbox` endpoint, the message is added to the relevant agent's mailbox and the agent can process it.

**Port:** 8080 (inside Docker container)

**Important Endpoints:**

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/agents` | GET | List all agents |
| `/agents/{name}` | GET | Agent details |
| `/agents/{name}/inbox` | POST | Send message to agent |
| `/workspaces` | GET | Workspace list |
| `/workspaces/{ws}/artifacts/{art}` | GET | Artifact status |

---

## 📦 Docker Compose Connection

Docker Compose allows managing multiple containers with a single configuration file. In this project, JaCaMo and Nginx run as two separate containers. Docker automatically creates a bridge network and containers can access each other by their names (e.g., `jacamo`). The `expose` command opens the port only within the Docker network, while `ports` opens it to the outside world.

```yaml
services:
  jacamo:
    build: .
    container_name: jacamo-web-demo-restaurant-master
    expose:
      - "8080"  # Only accessible within Docker network
    
  nginx:
    image: nginx:alpine
    container_name: jacamo-web-demo-restaurant-nginx
    ports:
      - "8080:80"  # External:8080 → Container:80
    volumes:
      - ./simulation.html:/usr/share/nginx/html/simulation.html
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - jacamo
```

**Docker Network:**
- Nginx accesses JaCaMo via `http://jacamo:8080`
- The `jacamo` name is resolved by Docker DNS (container in the same network)
- JaCaMo port is closed to the outside world, only Nginx can access it

---

## 🔄 Complete Flow Example: Pizza Order

The following flow shows the entire process from when a user orders pizza from the web interface to when the food is prepared and served. Each step clearly shows which component is running and how data flows.

```
1. User clicks "Send Order" button
   ↓
2. JavaScript: fetch('/agents/waiter/inbox', {...pizza...})
   ↓
3. Browser → Nginx:8080 → POST /agents/waiter/inbox
   ↓
4. Nginx → JaCaMo:8080 → POST /agents/waiter/inbox (proxy_pass)
   ↓
5. JaCaMo: Places message in waiter agent's inbox
   ↓
6. waiter.asl: +!takeOrder(customer1, pizza) plan is triggered
   ↓
7. waiter → cook: .send(cook, achieve, prepareFood(...))
   ↓
8. cook.asl: Waits 15 seconds, .send(waiter, tell, foodReady(...))
   ↓
9. simulation.html: pollJaCaMoStatus() → Polls OrderBoard artifact
   ↓
10. UI updates: Pending → Cooking → Completed
```

---

## 🔑 Why is Nginx Needed?

This system wouldn't work without Nginx because browsers block direct requests to different ports or origins for security reasons (CORS policy). Nginx solves this problem by managing all requests through a single origin.

| Reason | Description |
|--------|-------------|
| **CORS Solution** | Browser throws security error when making requests to different origins. Nginx provides same-origin proxy. |
| **Static File** | `simulation.html` is not part of JaCaMo, Nginx serves it. |
| **Port Consolidation** | Both HTML and API access through a single port (8080). |
| **Security** | JaCaMo internal port stays closed to the outside world. |
