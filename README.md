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

### 📋 Customer4 Oluşturma Senaryosu

Aşağıda `customer4` adında yeni bir müşteri agent'ı oluşturma adımları verilmiştir:

1. **Tarayıcıda Aç:** `http://localhost:8080/agent_new.html`
2. **İsim Gir:** `customer4` yazıp Enter'a bas.
3. **Doğrula:** `http://localhost:8080/agents.html` adresinde `customer4`'ün listelendiğini gör.
4. **Durum:** Agent şu an "default" durumda. Davranış kodu olmadığı için pasiftir.

#### Agent'ı Aktif Hale Getirmek İçin
Projenin `restaurant.jcm` dosyasına aşağıdaki satırı ekleyin:

```
agent customer4 : customer.asl {
    focus: diningRoom.tables
    focus: diningRoom.orderBoard
    join: restaurantOrg.serviceTeam.rcustomer
}
```

Ardından `docker-compose down && docker-compose up --build` ile sistemi yeniden başlatın.
