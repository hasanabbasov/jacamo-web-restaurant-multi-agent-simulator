/*
 * Customer Agent - Restaurant Multi-Agent System
 * Rol: Sipariş veren müşteri
 * Amaç: Yemek siparişi vermek ve yemeğini almak
 * 
 * 🍽️ İkonlar: 🧑 Müşteri, 🍕 Pizza, 🍔 Burger, 🥗 Salad, 🍝 Pasta
 */

// Initial beliefs
hungry(true).
preferredFood(pizza).

// Initial goal
!start.

+!start <- 
    .my_name(Me);
    .print("═══════════════════════════════════════════════════════");
    .print("🧑 MÜŞTERİ ", Me, " - Restorana geldi!");
    .print("═══════════════════════════════════════════════════════");
    .wait(1000);
    !requestTable.

// Moise organizational goals
+!seatCustomer[scheme(S),source(self)] <-
    .my_name(Me);
    .print("🧑 [ORG] ", Me, " fulfilling seatCustomer goal");
    !requestTable.

+!takePayment[scheme(S),source(self)] <-
    .my_name(Me);
    .print("🧑 [ORG] ", Me, " fulfilling takePayment goal");
    !requestBill.

// ========== MASA TALEBİ ==========
+!requestTable <-
    .my_name(Me);
    .print("🧑 [MASA] ", Me, " masa istiyor...");
    .send(waiter, achieve, assignTable(Me)).

// Masa atandığında
+tableAssigned(TableId)[source(waiter)] <-
    .my_name(Me);
    .print("═══════════════════════════════════════════════════════");
    .print("🧑 [MASA] ", Me, " Masa ", TableId, "'e oturdu!");
    .print("═══════════════════════════════════════════════════════");
    .wait(500);
    !orderFood.

// ========== SİPARİŞ ==========
+!orderFood : preferredFood(Food) <-
    .my_name(Me);
    .print("🧑 [SİPARİŞ] ", Me, " sipariş veriyor: ", Food);
    .send(waiter, achieve, takeOrder(Me, Food)).

// Sipariş onaylandığında
+orderReceived(Food)[source(waiter)] <-
    .my_name(Me);
    .print("🧑 [SİPARİŞ] ", Me, " sipariş onaylandı: ", Food);
    .print("🧑 [SİPARİŞ] ", Me, " yemeğini bekliyor...").

// ========== YEMEK SERVİSİ ==========
+foodServed(Food)[source(waiter)] <-
    .my_name(Me);
    .print("═══════════════════════════════════════════════════════");
    .print("🧑 [YEMEK] ", Me, " yemeği aldı: ", Food, " 🍽️");
    .print("🧑 [YEMEK] ", Me, " yiyor...");
    .print("═══════════════════════════════════════════════════════");
    .wait(3000);
    -hungry(true);
    +hungry(false);
    .print("🧑 [YEMEK] ", Me, " yemeğini bitirdi! 😋");
    .wait(1000);
    !requestBill.

// ========== HESAP ==========
+!requestBill <-
    .my_name(Me);
    .print("🧑 [HESAP] ", Me, " hesap istiyor...");
    .send(waiter, achieve, getBill(Me)).

// Hesap geldiğinde
+billReady(Amount)[source(waiter)] <-
    .my_name(Me);
    .print("🧑 [HESAP] ", Me, " hesap geldi: $", Amount);
    .print("🧑 [HESAP] ", Me, " ödeme yapıyor...");
    .send(cashier, achieve, processPayment(Me, Amount)).

// ========== ÖDEME TAMAMLANDI ==========
+paymentComplete[source(cashier)] <-
    .my_name(Me);
    .print("═══════════════════════════════════════════════════════");
    .print("🧑 [ÇIKIŞ] ", Me, " ödeme tamamlandı!");
    .print("🧑 [ÇIKIŞ] ", Me, " restorana teşekkür ediyor. 👋");
    .print("═══════════════════════════════════════════════════════");
    .send(waiter, achieve, freeTable(Me)).

// ========== HATA DURUMU ==========
+foodUnavailable(Food)[source(waiter)] <-
    .my_name(Me);
    .print("🧑 [HATA] ", Me, " ", Food, " bulunamadı, başka sipariş veriyor...");
    -preferredFood(_);
    +preferredFood(burger);
    !orderFood.

{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }
{ include("$moiseJar/asl/org-obedient.asl") }
