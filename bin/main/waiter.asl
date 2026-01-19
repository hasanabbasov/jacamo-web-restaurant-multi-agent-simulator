/*
 * Waiter Agent - Restaurant Multi-Agent System
 * Rol: Koordinatör garson
 * Amaç: Siparişleri almak, mutfağa iletmek, servis yapmak
 * 
 * 🍽️ İkonlar: 🧑‍🍳 Garson, 📝 Sipariş, 🍽️ Servis
 * 
 * JaCaMo-Web üzerinden mesaj gönderebilirsiniz:
 * POST http://localhost:8080/agents/waiter/inbox
 * {"performative": "achieve", "content": "takeOrder(webCustomer, pizza)"}
 */

// Initial beliefs - MUST be at the top
tableCount(0).
orderCount(0).

// Initial goal
!start.

+!start <- 
    .print("═══════════════════════════════════════════════════════");
    .print("🧑‍🍳 GARSON - Restoran servise hazır!");
    .print("═══════════════════════════════════════════════════════");
    .print("📋 JaCaMo-Web: http://localhost:8080");
    .print("📋 Sipariş göndermek için waiter agent'ına mesaj gönderin");
    .print("═══════════════════════════════════════════════════════").

// Moise organizational goals
+!takeOrder[scheme(S),source(self)] <-
    .print("🧑‍🍳 [ORG] Ready to take orders").
    
+!serveFood[scheme(S),source(self)] <-
    .print("🧑‍🍳 [ORG] Ready to serve food").

// ========== MASA ATAMA ==========
+!assignTable(Customer)[source(S)] <-
    .print("═══════════════════════════════════════════════════════");
    .print("🧑‍🍳 [MASA] Müşteri geldi: ", Customer);
    assignTable(Customer);
    .print("🧑‍🍳 [MASA] Masa atandı: ", Customer);
    .print("═══════════════════════════════════════════════════════").

// Masa atandığında (artifact signal)
+tableAssigned(TableId, Customer)[source(percept)] <-
    .print("🧑‍🍳 [MASA] Masa ", TableId, " → ", Customer);
    if (Customer \== webCustomer) {
        .send(Customer, tell, tableAssigned(TableId))
    }.

// ========== SİPARİŞ ALMA ==========
// Bu plan hem agent'lardan hem de JaCaMo-Web'den gelen siparişleri kabul eder
+!takeOrder(Customer, Food)[source(S)] <-
    .print("═══════════════════════════════════════════════════════");
    .print("🧑‍🍳 [SİPARİŞ] 📝 Yeni sipariş alındı!");
    .print("🧑‍🍳 [SİPARİŞ] Müşteri: ", Customer);
    .print("🧑‍🍳 [SİPARİŞ] Yemek: ", Food);
    .print("🧑‍🍳 [SİPARİŞ] Kaynak: ", S);
    .print("═══════════════════════════════════════════════════════");
    
    // Update order count
    ?orderCount(N);
    -+orderCount(N+1);
    .print("🧑‍🍳 [SİPARİŞ] Toplam sipariş sayısı: ", N+1);
    
    // Record order in artifact - siparişler kuyrukta birikir
    recordOrder(Customer, Food);
    addToOrder(Customer, Food);
    
    // Notify customer if it's an agent and NOT webCustomer
    if (S \== self & S \== webCustomer) {
        .send(S, tell, orderReceived(Food))
    };
    
    // NOT sending to cook directly! Cook polls the queue.
    .print("🧑‍🍳 [KUYRUK] Sipariş kuyruğa eklendi - cook alacak").

// ========== SERVİS ==========
// Yemek hazır olduğunda (aşçıdan gelen mesaj)
// Source'u esnek tutuyoruz - herhangi bir kaynaktan kabul et
+foodReady(Customer, Food)[source(S)] <-
    .print("═══════════════════════════════════════════════════════");
    .print("🧑‍🍳 [SERVİS] 🍽️ Yemek HAZIR!");
    .print("🧑‍🍳 [SERVİS] Kaynak: ", S);
    .print("🧑‍🍳 [SERVİS] Yemek: ", Food);
    .print("🧑‍🍳 [SERVİS] Müşteri: ", Customer);
    .print("═══════════════════════════════════════════════════════");
    
    // Artifact'e bildir
    deliverFood(Customer, Food);
    
    .print("🧑‍🍳 [SERVİS] ✅ ", Food, " → ", Customer, " SERVİS EDİLDİ!");
    .print("═══════════════════════════════════════════════════════");
    
    // Müşteriye bildir (webCustomer değilse)
    if (Customer \== webCustomer) {
        .print("🧑‍🍳 [SERVİS] Müşteriye bildirim gönderiliyor: ", Customer);
        .send(Customer, tell, foodServed(Food))
    } else {
        .print("🧑‍🍳 [SERVİS] Web müşterisi - bildirim gerekmiyor")
    }.

// ========== HESAP ==========
+!getBill(Customer)[source(S)] <-
    .print("═══════════════════════════════════════════════════════");
    .print("🧑‍🍳 [HESAP] 💰 Hesap hazırlanıyor: ", Customer);
    calculateBill(Customer, Amount);
    .print("🧑‍🍳 [HESAP] Tutar: $", Amount);
    .print("═══════════════════════════════════════════════════════");
    if (S \== webCustomer) {
        .send(S, tell, billReady(Amount))
    }.

// ========== MASA TEMİZLEME ==========
+!freeTable(Customer)[source(S)] <-
    .print("═══════════════════════════════════════════════════════");
    .print("🧑‍🍳 [MASA] 🧹 Masa temizleniyor: ", Customer);
    freeTable(Customer);
    .print("🧑‍🍳 [MASA] Masa boşaltıldı");
    .print("═══════════════════════════════════════════════════════").

// ========== HATA DURUMU ==========
+foodFailed(Customer, Food)[source(cook)] <-
    .print("🧑‍🍳 [HATA] ❌ Yemek hazırlanamadı: ", Food, " for ", Customer);
    if (Customer \== webCustomer) {
        .send(Customer, tell, foodUnavailable(Food))
    }.

{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }
{ include("$moiseJar/asl/org-obedient.asl") }
