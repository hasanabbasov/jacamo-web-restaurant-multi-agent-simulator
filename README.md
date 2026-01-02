# 🍽️ Otonom Restoran Simülasyonu (JaCaMo & Docker)

Bu proje, **JaCaMo** (Jason, CArtAgO, Moise) platformu üzerine kurulu, **Docker** ile containerize edilmiş ve **Nginx** üzerinden görsel bir web arayüzü ile yönetilebilen otonom bir restoran simülasyonudur.

## 🌟 Proje Hakkında

Bu simülasyonda yapay zekalı "Agent"lar (Garson, Aşçı, Kasiyer, Müşteri) otonom olarak birbirleriyle iletişim kurar ve restoran süreçlerini yönetirler. Kullanıcılar bir web arayüzü üzerinden sisteme dahil olabilir ve sipariş verebilirler.

## 🏗️ Mimari ve Teknolojiler

Proje 4 ana katmandan oluşur, her biri farklı bir görevi üstlenir:

| Teknoloji | Görevi & Açıklaması |
|-----------|----------------------|
| **1. Agent Katmanı (Jason)** | **Beyin.** Agent'ların mantıksal kararlarını verir. `.asl` dosyalarında yazılır. (Örn: "Yemek hazırsa servis et"). |
| **2. Ortam Katmanı (CArtAgO)** | **Sahne.** Agent'ların içine girip işlem yaptığı Java nesneleridir. (Örn: Masa, Mutfak, Kasa). |
| **3. Ağ Katmanı (Nginx & API)** | **Köprü.** Dış dünyadan (Web) gelen istekleri Agent dünyasına taşır. |
| **4. Altyapı (Docker)** | **Kapsül.** Tüm sistemi tek bir pakette çalıştırır. |

---

## 🔍 Sınıf ve Dosya Detayları

### 🧠 1. Agent'lar (src/agt/*.asl)
Agent'lar birbirleriyle **ACL (Agent Communication Language)** mesajlaşma protokolü ile konuşurlar (`.send`).

*   **🧑‍🍳 Garson (`waiter.asl`)**: **Orkestra Şefi.**
    *   **Görevi:** Müşteriyi karşılar, masa atar, siparişi alır, mutfağa iletir, yemeği taşır, hesabı keser.
    *   **Kullandığı Artifactler:** `TableManager`, `OrderBoard`, `CashRegister`.
    *   **Önemli Planı:** `+!takeOrder(Customer, Food)` -> Sipariş gelince çalışır, mutfağa haber verir.

*   **👨‍🍳 Aşçı (`cook.asl`)**: **Üretici.**
    *   **Görevi:** Gelen siparişleri pişirir. Pişirme süresi boyunca meşgul olur.
    *   **Kullandığı Artifactler:** `Kitchen`, `OrderBoard`.
    *   **Önemli Mesajı:** `foodReady` -> Yemek bitince garsona "Hazır" der.

*   **🧑‍💼 Kasiyer (`cashier.asl`)**: **Finans.**
    *   **Görevi:** Ödemeleri işler, kasayı günceller.
    *   **Kullandığı Artifactler:** `CashRegister`.

*   **🧑 Müşteri (`customer.asl`)**: **Simülatör.**
    *   **Görevi:** Otonom olarak restorana gelir, sipariş verir, yer ve öder.

### 🛠️ 2. Artifact'ler (src/env/restaurant/*.java)
Java ile yazılmış, Agent'ların kullanabildiği "Akıllı Nesneler"dir.

*   **`TableManager.java`**:
    *   **Ne yapar:** Masa doluluk oranlarını yönetir.
    *   **Sinyal:** `tableAssigned` (Biri oturunca tüm agent'lara haber verir).
*   **`OrderBoard.java`**:
    *   **Ne yapar:** Siparişlerin durumunu (Bekliyor, Pişiyor, Hazır) takip eder. Simülasyon ekranındaki veriyi sağlar.
*   **`Kitchen.java`**:
    *   **Ne yapar:** Ocağın kapasitesini kontrol eder. Aşçı buraya "pişir" komutu gönderir.
*   **`CashRegister.java`**:
    *   **Ne yapar:** Menü fiyatlarını bilir ve ciroyu tutar. Garson buraya siparişi ekler (`addToOrder`), kasiyer ödemeyi alır.

### 📜 3. Organizasyon (src/org/restaurant.xml)
Agent'ların rollerini ve gruplarını belirler.
*   **Roles:** `waiter`, `cook`, `cashier`, `customer`.
*   **Scheme:** `restaurant_service` (Hizmet akışı).

---

## 🔄 İletişim Akışı: Bir Siparişin Yolculuğu

Siz `simulation.html` üzerinden **"Pizza"** siparişi verdiğinizde arka planda şu olaylar gerçekleşir:

1.  **WEB (Başlangıç):**
    *   JS kodu, REST API'ye POST isteği atar: `takeOrder(webCustomer, pizza)`.
    *   Nginx bu isteği Garson Agent'ının (waiter) posta kutusuna koyar.

2.  **AGENT (Karar):**
    *   **Garson** mesajı okur (`+!takeOrder` planı tetiklenir).
    *   **Garson**, `OrderBoard` artifact'ine "Yeni sipariş yaz" der.
    *   **Garson**, `CashRegister` artifact'ine "Hesaba pizza ekle" der (`addToOrder` - **Fiyat burada belirlenir**).
    *   **Garson**, **Aşçı** agent'ına mesaj atar: `.send(cook, achieve, prepareFood)`.

3.  **ÜRETİM (Mutfak):**
    *   **Aşçı** mesajı alır, `Kitchen` artifact'ini kullanır (Ocak meşgul olur).
    *   Simüle edilen süre (5sn) geçer.
    *   **Aşçı** garsona geri mesaj atar: `tell, foodReady`.

4.  **SERVİS & FİNANS:**
    *   **Garson** yemeği alır, müşteriye "servis edildi" der.
    *   Yemek bitince **Müşteri** hesap ister.
    *   **Garson** `CashRegister`dan tutarı hesaplar (**Kasa: $25**).
    *   **Kasiyer** ödemeyi onaylar ve günlük ciro güncellenir.

5.  **WEB (Sonuç):**
    *   Tüm bu süreç boyunca Agent'lar terminale log basar.
    *   Simülasyon sayfasındaki animasyonlar ilerler.

---

## 🌐 Web Arayüzü Detayları

*   **`simulation.html`**: Görsel arayüzdür. Agent değildir, sadece Agent'lara istek yollayan bir "kumanda"dır.
*   **Nginx Proxy**: `localhost:8080/simulation.html` adresinde çalışır. `/agents/` endpoint'ine gelen istekleri arka plandaki JaCaMo sistemine yönlendirir (CORS sorununu çözer).

## 🚀 Kurulum ve Çalıştırma

### Başlatma
Terminali proje klasöründe açın ve şu komutu çalıştırın:

```bash
docker-compose up --build
```

### Kullanım

1. **Görsel Simülasyon**: [http://localhost:8080/simulation.html](http://localhost:8080/simulation.html)
   - Müşteri seçip sipariş verin.
2. **Canlı İzleme (Terminal)**:
   ```bash
   docker logs -f jacamo-mas
   ```

---

## 🖥️ JaCaMo-Web Arayüzü Detayları

Proje çalıştırıldığında, JaCaMo-Web arayüzü üzerinden sistemi yönetebilir ve izleyebilirsiniz.

### 📍 Erişim URL'leri

| URL | Sayfa | Açıklama |
|-----|-------|----------|
| `/agents.html` | **Agent Listesi** | Tüm aktif agent'ları listeler. Her birine tıklayarak detaylarını görebilirsiniz. |
| `/agent_new.html` | **Yeni Agent Oluştur** | Runtime sırasında yeni agent eklemenizi sağlar. |
| `/workspaces.html` | **Environment (Ortam)** | `diningRoom`, `kitchenArea` gibi workspace'leri ve içindeki artifact'leri gösterir. |
| `/oe.html` | **Organisation** | `restaurantOrg` organizasyonunu, grupları, rolleri ve şemaları görüntüler. |

---

### 🆕 Yeni Agent Oluşturma (Runtime)

JaCaMo-Web, çalışma anında yeni agent oluşturmanıza olanak tanır. İşlem şu şekilde gerçekleşir:

#### Adım 1: Agent Oluşturma Sayfasına Git
```
http://localhost:8080/agent_new.html
```

#### Adım 2: Agent Adını Gir
- Sayfada sadece bir **text input** alanı bulunur.
- Yeni agent adını yazın (örn: `customer4`).
- **Enter** tuşuna basın.

#### Adım 3: Agent Oluşturuldu
- Agent sistem tarafından "boş bir kabuk" olarak oluşturulur.
- Başlangıçta:
  - **Belief'leri yoktur** (boş zihin).
  - **Hiçbir workspace'e bağlı değildir**.
  - **Hiçbir organizasyon rolü üstlenmemiştir**.

#### Adım 4: Agent'a Davranış ve Rol Atama
Yeni oluşturulan agent'ın işlevsel olması için:

1. **ASL Kodu Yükleme**: Agent'a `customer.asl` gibi bir davranış kodu atanmalıdır. Bu genellikle `.jcm` dosyasında tanımlanır.

2. **Organizasyona Katılma**: Agent'ın rol alması için organizasyona katılması gerekir:
   ```
   Örnek: customer4, "serviceTeam" grubunda "rcustomer" rolünü üstlenir.
   ```

3. **Workspace'e Odaklanma (Focus)**: Agent'ın artifact'lerle etkileşime geçmesi için ilgili workspace'e bağlanması gerekir:
   ```
   Örnek: customer4, "diningRoom" workspace'indeki "tables" artifact'ine odaklanır.
   ```

> ⚠️ **Not:** `agent_new.html` yalnızca agent'ı oluşturur. Rol ve workspace atamaları genellikle agent'ın başlangıç kodunda (ASL) veya JaCaMo konfigürasyon dosyasında (`.jcm`) yapılır.

---

### 🌍 Environment (Ortam) Yönetimi

**URL:** `http://localhost:8080/workspaces.html`

Bu sayfa, agent'ların içinde çalıştığı **workspace'leri** ve bu workspace'lerdeki **artifact'leri** gösterir.

#### Workspace Nedir?
- Agent'ların "odaklanarak" etkileşime geçtiği sanal ortamlardır.
- Örnek workspace'ler:
  - `diningRoom`: Masalar ve sipariş tahtası
  - `kitchenArea`: Mutfak ve ocak

#### Artifact Nedir?
- Workspace içindeki Java nesneleridir.
- Agent'lar bunlara `.focus` ile bağlanır ve operasyonlarını çağırır.
- Örnek artifact'ler: `tables`, `orderBoard`, `kitchen`, `cashRegister`

#### Web Arayüzünde Görüntüleme
- Her workspace'e tıkladığınızda içindeki artifact'leri görebilirsiniz.
- Artifact özelliklerini (observable properties) canlı olarak izleyebilirsiniz.

---

### 🏛️ Organisation (Organizasyon) Yönetimi

**URL:** `http://localhost:8080/oe.html`

Bu sayfa, agent'ların sosyal yapısını ve görev dağılımını gösterir.

#### Organizasyon Yapısı (`restaurantOrg`)

```
restaurantOrg
├── Gruplar (Groups)
│   └── serviceTeam
│       ├── rwaiter (Garson rolü)
│       ├── rcook (Aşçı rolü)
│       ├── rcashier (Kasiyer rolü)
│       └── rcustomer (Müşteri rolü)
│
└── Şemalar (Schemes)
    └── mainService
        ├── mWaiter (Garson görevi)
        ├── mCook (Aşçı görevi)
        └── mCustomer (Müşteri görevi)
```

#### Rol Atama
- Agent'lar grup içinde bir rol **üstlenir** (adopt role).
- Örnek: `waiter` agent'ı `serviceTeam` grubunda `rwaiter` rolünü üstlenmiştir.

#### Web Arayüzünde Görüntüleme
- Organizasyon grafiği Graphviz ile görselleştirilir.
- Hangi agent'ın hangi rolü üstlendiğini görebilirsiniz.
- "create role" gibi seçeneklerle yeni roller tanımlayabilirsiniz (ileri düzey).

---

### 📋 Runtime Agent Tam Yapılandırma (Customer4 Örneği)

Web arayüzünden oluşturulan agent'lar başlangıçta "boş kabuk"tur. Onları `customer1` gibi tam işlevsel hale getirmek için aşağıdaki adımları izleyin:

#### Yöntem 1: Web Arayüzü Üzerinden (Önerilen)

**Adım 1: Agent Oluştur**
- `http://localhost:8080/agent_new.html` → `customer4` yazıp Enter.

**Adım 2: Belief Ekle (Komut Arayüzü)**
- `http://localhost:8080/agent.html?agent=customer4` adresine git.
- Üstteki "Command" kutusuna yaz ve Enter'a bas:
```
+preferredFood(pasta)
```

**Adım 3: ASL Kodu Düzenle**
- Sayfanın altındaki `customer4.asl` linkine tıkla.
- Editörde aşağıdaki kodu yapıştır:

```prolog
// Customer 4 - Runtime oluşturulmuş agent
preferredFood(pasta).

!init.

+!init <-
    joinWorkspace("diningRoom", WspId);
    lookupArtifact("orderBoard", OrderId);
    focus(OrderId);
    lookupArtifact("tables", TablesId);
    focus(TablesId);
    .print("✅ Customer4 başlatıldı ve diningRoom'a bağlandı!").

{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }
```

**Adım 4: Kaydet ve Çalıştır**
- "Save" butonuna tıkla.
- Komut kutusuna `!init` yazıp Enter'a bas.

**Adım 5: Doğrula**
- "Beliefs" bölümünü aç → `tableStatus`, `currentStatus` gibi artifact perception'ları görmelisin.
- Environment grafiğinde `customer4`'ün `diningRoom` workspace'i içinde olduğunu gör.

---

#### Önemli Komutlar (Command Interface)

| Komut | Açıklama |
|-------|----------|
| `+belief(value)` | Belief ekle |
| `-belief(value)` | Belief sil |
| `!goal` | Goal başlat |
| `.print(message)` | Terminale log yaz |
| `.send(agent, tell, msg)` | Diğer agent'a mesaj gönder |
| `+{ +!goal <- action }` | Plan ekle |

---

#### Yöntem 2: JCM Dosyası ile Kalıcı Ekleme

Sistem yeniden başladığında agent'ın otomatik oluşması için `restaurant.jcm` dosyasına ekleyin:

```
agent customer4 : customer.asl {
    focus: diningRoom.orderBoard
    focus: diningRoom.tables
    beliefs: preferredFood(pasta)
}
```

Organizasyona dahil etmek için `players` satırına ekleyin:
```
players: customer1 rcustomer,
         customer2 rcustomer,
         customer4 rcustomer,  // ← YENİ
         waiter rwaiter,
         ...
```

Ardından `docker-compose down && docker-compose up --build` ile yeniden başlatın.

---

### 🎯 Customer3 Oluşturma Senaryosu (Tam Örnek)

`customer3` adında yeni bir müşteri agent'ı oluşturup tam işlevsel hale getirmek için:

#### Adım 1: Agent Oluştur
- `http://localhost:8080/agent_new.html` adresine git
- `customer3` yazıp Enter'a bas

#### Adım 2: ASL Editörüne Git
- `http://localhost:8080/agent.html?agent=customer3` adresine git
- Sayfanın altındaki `customer3.asl` linkine tıkla

#### Adım 3: Aşağıdaki Kodu Yapıştır

```prolog
// ═══════════════════════════════════════════════════════════════
// Customer3 Agent - Runtime Oluşturulmuş Müşteri
// ═══════════════════════════════════════════════════════════════

// Başlangıç Belief'leri
preferredFood(salad).      // Bu müşteri salad seviyor
myBudget(50).              // $50 bütçesi var

// Başlangıç Goal'ı
!init.

// ═══════════════════════════════════════════════════════════════
// INIT PLAN - Agent başladığında çalışır
// ═══════════════════════════════════════════════════════════════
+!init <-
    .print("═══════════════════════════════════════════════════════");
    .print("🧑 [CUSTOMER3] Merhaba! Ben yeni bir müşteriyim.");
    .print("═══════════════════════════════════════════════════════");
    
    // Workspace'e katıl
    joinWorkspace("diningRoom", WspId);
    .print("🧑 [CUSTOMER3] diningRoom'a girdim.");
    
    // Artifact'lere odaklan
    lookupArtifact("orderBoard", OrderId);
    focus(OrderId);
    lookupArtifact("tables", TablesId);
    focus(TablesId);
    .print("🧑 [CUSTOMER3] Masalara ve sipariş tahtasına bakıyorum.");
    
    .print("🧑 [CUSTOMER3] Hazırım! Simülasyondan sipariş verebilirsiniz.").

// ═══════════════════════════════════════════════════════════════
// Sipariş Alma - Waiter'dan gelen mesajları işle
// ═══════════════════════════════════════════════════════════════
+orderReceived(Food)[source(S)] <-
    .print("🧑 [CUSTOMER3] Siparişim onaylandı: ", Food);
    .print("🧑 [CUSTOMER3] Yemeğimi bekliyorum...").

+foodServed(Food)[source(S)] <-
    .print("═══════════════════════════════════════════════════════");
    .print("🧑 [CUSTOMER3] Yemeğim geldi: ", Food, " 🍽️");
    .print("🧑 [CUSTOMER3] Yiyorum...");
    .print("═══════════════════════════════════════════════════════");
    .wait(3000);
    .print("🧑 [CUSTOMER3] Yemeğimi bitirdim! 😋");
    !askForBill.

+!askForBill <-
    .print("🧑 [CUSTOMER3] Hesap istiyorum...");
    .send(waiter, achieve, getBill(customer3)).

+billReady(Amount)[source(S)] <-
    .print("🧑 [CUSTOMER3] Hesap geldi: $", Amount);
    .print("🧑 [CUSTOMER3] Ödeme yapıyorum...");
    .send(cashier, achieve, processPayment(customer3, Amount)).

+paymentComplete[source(S)] <-
    .print("═══════════════════════════════════════════════════════");
    .print("🧑 [CUSTOMER3] ✅ Ödeme tamamlandı! Teşekkürler!");
    .print("═══════════════════════════════════════════════════════").

// CArtAgO ve Moise template'leri
{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }
```

#### Adım 4: Kaydet ve Çalıştır
1. "Save" butonuna tıkla
2. Komut kutusuna `!init` yaz ve Enter'a bas
3. Terminal'de mesajları gör: `docker logs -f jacamo-mas`

#### Adım 5: Simülasyondan Test Et
1. `http://localhost:8080/simulation.html` adresine git
2. "Müşteri Seç" dropdown'ında artık `customer3` görünmeli (10 saniye bekle)
3. `customer3` seçip bir yemek sipariş ver
4. Terminal'de tüm akışı izle
