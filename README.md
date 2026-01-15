# 🍽️ JaCaMo Restaurant Multi-Agent Simulation

## İlerleme Raporu

**Proje:** Otonom Restoran Simülasyonu  
**Platform:** JaCaMo (Jason + CArtAgO + Moise)  
**Containerization:** Docker + Nginx  
**Durum:** ✅ Aktif Geliştirme

---

## 📋 1. Proje Özeti

Bu proje, yapay zekalı otonom agent'ların birbirleriyle iletişim kurarak bir restoran işletmesini simüle ettiği çok-agent sistemidir.

### 🎯 Amaç
- Multi-Agent Systems (MAS) konseptlerini pratik bir senaryoda göstermek
- JaCaMo platformunun (Jason, CArtAgO, Moise) entegre kullanımını sergilemek
- Docker containerization ile kolay deployment sağlamak
- Web arayüzü ile gerçek zamanlı agent etkileşimi sunmak

### 🏆 Temel Özellikler
| Özellik | Açıklama |
|---------|----------|
| **Otonom Agent'lar** | Waiter, Cook, Cashier, Customer |
| **Real-time Web UI** | Sipariş ve kuyruk izleme |
| **Agent İletişimi** | ACL mesajlaşma protokolü |
| **Artifact Sistemi** | Paylaşılan ortam nesneleri |
| **Organizasyon** | Rol ve görev dağılımı |

---

## 🚀 2. Projeyi Başlatma

### Gereksinimler
- Docker Desktop
- Port 8080'in boş olması

### Başlatma Komutu
```bash
cd jacamo-web-demo-marketplace-master
docker-compose up --build
```

### Erişim URL'leri
| URL | Sayfa |
|-----|-------|
| http://localhost:8080/simulation.html | Görsel Simülasyon |
| http://localhost:8080/agents.html | Agent Listesi |
| http://localhost:8080/workspaces.html | Environment |
| http://localhost:8080/oe.html | Organizasyon |
| http://localhost:8080/agent_new.html | Yeni Agent Oluştur |

### Logları İzleme
```bash
docker logs -f jacamo-web-demo-restaurant-master
```

### Durdurma
```bash
docker-compose down
```

---

## 🏗️ 3. Proje Yapısı

```
jacamo-web-demo-marketplace-master/
├── src/
│   ├── agt/                    # Agent Kodları (.asl)
│   │   ├── waiter.asl          # Garson agent
│   │   ├── cook.asl            # Aşçı agent
│   │   ├── cashier.asl         # Kasiyer agent
│   │   └── customer.asl        # Müşteri agent
│   │
│   ├── env/restaurant/         # Artifact'ler (Java)
│   │   ├── TableManager.java   # Masa yönetimi
│   │   ├── OrderBoard.java     # Sipariş takibi
│   │   ├── Kitchen.java        # Mutfak operasyonları
│   │   └── CashRegister.java   # Kasa ve fiyatlandırma
│   │
│   └── org/                    # Organizasyon
│       └── restaurant.xml      # Rol ve grup tanımları
│
├── restaurant.jcm              # JaCaMo konfigürasyonu
├── simulation.html             # Web arayüzü
├── docker-compose.yml          # Container orchestration
├── Dockerfile                  # JaCaMo image tanımı
└── nginx.conf                  # Reverse proxy
```

---

## 🤖 4. Agent Sınıfları (src/agt/)

### 4.1 Waiter Agent (`waiter.asl`)
**Rol:** Koordinatör - Tüm akışı yönetir

| Plan | Tetikleyici | İşlem |
|------|-------------|-------|
| `+!takeOrder(C, F)` | Sipariş gelince | OrderBoard'a kaydet, Cook'a gönder |
| `+foodReady(C, F)` | Yemek hazır | Müşteriye servis et |
| `+!getBill(C)` | Hesap istenir | CashRegister'dan hesapla |

**Kullandığı Artifact'ler:** `TableManager`, `OrderBoard`, `CashRegister`

### 4.2 Cook Agent (`cook.asl`)
**Rol:** Üretici - Yemek hazırlar

| Plan | Tetikleyici | İşlem |
|------|-------------|-------|
| `+!prepareFood(C, F)` | Waiter'dan sipariş | Pişirme süresi bekle, hazır olunca bildir |

**Pişirme Süreleri:**
- 🍕 Pizza: 15 saniye
- 🍔 Burger: 13 saniye
- 🥗 Salad: 12 saniye
- 🍝 Pasta: 14 saniye
- 🥩 Steak: 17 saniye

### 4.3 Cashier Agent (`cashier.asl`)
**Rol:** Finans - Ödemeleri işler

| Plan | İşlem |
|------|-------|
| `+!processPayment(C, A)` | Ödemeyi kabul et, kasa güncelle |

### 4.4 Customer Agent (`customer.asl`)
**Rol:** Simülatör - Sipariş verir, yer, öder

| Plan | İşlem |
|------|-------|
| `+!init` | Workspace'e katıl, artifact'lere odaklan |
| `+orderReceived` | Sipariş onayını al |
| `+foodServed` | Yemeği al, ye, hesap iste |

---

## 🛠️ 5. Artifact Sınıfları (src/env/restaurant/)

### 5.1 TableManager.java
**Amaç:** Masa rezervasyonu ve durumu

| Operation | Parametre | Sonuç |
|-----------|-----------|-------|
| `assignTable(customer)` | Müşteri adı | Masa atar, `tableAssigned` sinyali |
| `freeTable(customer)` | Müşteri adı | Masayı boşaltır |

**Observable Properties:**
- `tableStatus(id, status)` - Her masanın durumu

### 5.2 OrderBoard.java
**Amaç:** Sipariş takip tahtası (Frontend'e veri sağlar)

| Operation | İşlem |
|-----------|-------|
| `recordOrder(c, f)` | Yeni sipariş kaydet |
| `startCooking(f)` | Pişirme başladı |
| `finishCooking(f)` | Pişirme bitti |
| `deliverFood(c, f)` | Servis yapıldı |

**Observable Properties:**
- `pendingOrders` - Bekleyen sipariş sayısı
- `cookingOrders` - Pişen sipariş sayısı
- `completedOrders` - Tamamlanan sayısı
- `currentStatus` - Son durum mesajı

### 5.3 Kitchen.java
**Amaç:** Mutfak kapasitesi ve ocak yönetimi

| Operation | İşlem |
|-----------|-------|
| `useOven()` | Ocağı meşgul et |
| `releaseOven()` | Ocağı serbest bırak |

### 5.4 CashRegister.java
**Amaç:** Fiyatlandırma ve ödeme

| Operation | İşlem |
|-----------|-------|
| `addToOrder(c, f)` | Müşteri hesabına yemek ekle |
| `calculateBill(c)` | Toplam hesabı hesapla |
| `processPayment(c, a)` | Ödemeyi işle |

**Fiyat Listesi:**
- Pizza: $25
- Burger: $18
- Salad: $12
- Pasta: $20
- Steak: $45

---

## 🏛️ 6. Organization (src/org/restaurant.xml)

Moise organizasyon yapısı, agent'ların sosyal ilişkilerini, rollerini ve görevlerini tanımlar. Bu XML dosyası üç ana bölümden oluşur.

### 6.1 Structural Specification (Yapısal Tanım)

Agent'ların rollerini ve gruplarını belirler.

**Roller:**
| Rol ID | Açıklama | Min-Max |
|--------|----------|---------|
| `rcustomer` | Müşteri rolü | 1-10 |
| `rwaiter` | Garson rolü | 1-3 |
| `rcook` | Aşçı rolü | 1-2 |
| `rcashier` | Kasiyer rolü | 1-1 |

**İletişim Bağlantıları:**
```
rcustomer ↔ rwaiter   (sipariş, servis)
rwaiter   ↔ rcook     (mutfak koordinasyonu)
rwaiter   ↔ rcashier  (hesap)
rcustomer ↔ rcashier  (ödeme)
```

### 6.2 Functional Specification (İşlevsel Tanım)

Hizmet akışını (scheme) ve görevleri (mission) tanımlar.

**Service Flow (Sıralı Akış):**
```
seatCustomer → takeOrder → cookFood → serveFood → takePayment
```

**Görevler (Missions):**
| Mission | Rol | Hedefler |
|---------|-----|----------|
| `mCustomer` | rcustomer | seatCustomer, takePayment |
| `mWaiter` | rwaiter | takeOrder, serveFood |
| `mCook` | rcook | cookFood |
| `mCashier` | rcashier | takePayment |

### 6.3 Normative Specification (Normatif Tanım)

Rollerin zorunlu görevlerini (obligation) belirler.

| Norm | Rol | Zorunluluk |
|------|-----|------------|
| `normWaiterOrder` | rwaiter | Sipariş almalı |
| `normCookFood` | rcook | Yemek hazırlamalı |
| `normCashierPayment` | rcashier | Ödeme almalı |
| `normCustomerPay` | rcustomer | Ödeme yapmalı |

---

## 🔄 7. İletişim Akışı

```
┌─────────────┐     (1) takeOrder      ┌─────────────┐
│  Customer   │ ──────────────────────▶ │   Waiter    │
└─────────────┘                        └──────┬──────┘
                                              │
                    (2) prepareFood           │
                    ┌─────────────────────────┘
                    ▼
              ┌─────────────┐
              │    Cook     │ ◄── (3) .wait(cookingTime)
              └──────┬──────┘
                     │
                     │ (4) foodReady
                     ▼
              ┌─────────────┐
              │   Waiter    │
              └──────┬──────┘
                     │
                     │ (5) foodServed
                     ▼
              ┌─────────────┐     (6) getBill      ┌─────────────┐
              │  Customer   │ ──────────────────▶  │   Waiter    │
              └─────────────┘                      └──────┬──────┘
                                                          │
                     ┌────────────────────────────────────┘
                     │ (7) processPayment
                     ▼
              ┌─────────────┐
              │   Cashier   │
              └─────────────┘
```

---

## 🧪 7. Customer4 Örneği (Runtime Agent Oluşturma)

Bu bölümde, çalışma zamanında yeni bir müşteri agent'ı oluşturup yapılandırmayı gösteriyoruz.

### Adım 1: Agent Oluştur
```
http://localhost:8080/agent_new.html
→ "customer4" yaz, Enter'a bas
```

### Adım 2: Agent Sayfasına Git
```
http://localhost:8080/agent.html?agent=customer4
```

### Adım 3: ASL Kodu Yükle

Sayfanın altındaki `customer4.asl` linkine tıklayın ve editöre şu kodu yapıştırın:

```prolog
// ═══════════════════════════════════════════════════════
// Customer4 Agent - Runtime Generated
// ═══════════════════════════════════════════════════════

// Initial Beliefs
preferredFood(pasta).
myBudget(100).

// Initial Goal
!init.

// ═══════════════════════════════════════════════════════
// INIT - Agent başlatma
// ═══════════════════════════════════════════════════════
+!init <-
    .print("═══════════════════════════════════════════════════════");
    .print("🧑 [CUSTOMER4] Merhaba! Ben yeni bir müşteriyim.");
    .print("🧑 [CUSTOMER4] Tercihim: pasta, Bütçem: $100");
    .print("═══════════════════════════════════════════════════════");
    
    // Workspace'e katıl
    joinWorkspace("diningRoom", WspId);
    .print("🧑 [CUSTOMER4] diningRoom workspace'ine katıldım.");
    
    // Artifact'lere odaklan
    lookupArtifact("orderBoard", OrderId);
    focus(OrderId);
    lookupArtifact("tables", TablesId);
    focus(TablesId);
    .print("🧑 [CUSTOMER4] Artifact'lere odaklandım.");
    
    .print("🧑 [CUSTOMER4] ✅ Hazırım! simulation.html'den sipariş verebilirsiniz.").

// ═══════════════════════════════════════════════════════
// Sipariş ve Servis Planları
// ═══════════════════════════════════════════════════════
+orderReceived(Food)[source(S)] <-
    .print("🧑 [CUSTOMER4] ✓ Siparişim onaylandı: ", Food);
    .print("🧑 [CUSTOMER4] Yemeğimi bekliyorum...").

+foodServed(Food)[source(S)] <-
    .print("═══════════════════════════════════════════════════════");
    .print("🧑 [CUSTOMER4] 🍽️ Yemeğim geldi: ", Food);
    .print("🧑 [CUSTOMER4] Yiyorum...");
    .print("═══════════════════════════════════════════════════════");
    .wait(3000);
    .print("🧑 [CUSTOMER4] Yemeğimi bitirdim! 😋");
    !askForBill.

+!askForBill <-
    .print("🧑 [CUSTOMER4] 💰 Hesap istiyorum...");
    .send(waiter, achieve, getBill(customer4)).

+billReady(Amount)[source(S)] <-
    .print("🧑 [CUSTOMER4] Hesap: $", Amount);
    .print("🧑 [CUSTOMER4] Ödeme yapıyorum...");
    .send(cashier, achieve, processPayment(customer4, Amount)).

+paymentComplete[source(S)] <-
    .print("═══════════════════════════════════════════════════════");
    .print("🧑 [CUSTOMER4] ✅ Ödeme tamamlandı! Teşekkürler!");
    .print("═══════════════════════════════════════════════════════").

// Templates
{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }
```

### Adım 4: Kaydet ve Başlat
1. **Save** butonuna tıkla
2. Üstteki Command kutusuna `!init` yaz ve Enter

### Adım 5: Test Et
1. http://localhost:8080/simulation.html adresine git
2. "Müşteri Seç" dropdown'unda `customer4` görünecek
3. Sipariş ver ve terminal'de akışı izle:
   ```bash
   docker logs -f jacamo-web-demo-restaurant-master
   ```

### Kalıcı Ekleme (Opsiyonel)
`restaurant.jcm` dosyasına ekleyerek sistem yeniden başladığında otomatik oluşmasını sağlayabilirsiniz:

```
agent customer4 : customer.asl {
    focus: diningRoom.orderBoard
    focus: diningRoom.tables
    beliefs: preferredFood(pasta)
}
```

---

## 📊 8. Mevcut Durum ve Sonraki Adımlar

### ✅ Tamamlanan
- [x] Docker containerization
- [x] Nginx reverse proxy
- [x] Web simülasyon arayüzü
- [x] Agent iletişim akışı
- [x] Gerçek zamanlı artifact polling
- [x] Dinamik müşteri dropdown
- [x] Pişirme süreleri (+10 saniye)
- [x] Light theme UI redesign

### 🔄 Devam Eden
- [ ] Priority queue algoritması (değer/süre sıralaması)
- [ ] Daha detaylı kuyruk görselleştirmesi
- [ ] Blackboard Pattern Dene!

### 📝 Notlar
- JaCaMo agent'ları terminalde detaylı log basar
- Frontend her 2 saniyede OrderBoard'u poll eder
- Yeni agent'lar dropdown'a otomatik eklenir

---

**Rapor Tarihi:** 2026-01-10  
**Proje Repository:** https://github.com/hasanabbasov/jacamo-web-restaurant-multi-agent-simulator
