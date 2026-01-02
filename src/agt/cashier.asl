/*
 * Cashier Agent - Restaurant Multi-Agent System
 * Rol: Kasiyer - ödeme işlemleri
 * Amaç: Müşteri ödemelerini almak
 * 
 * 💰 İkonlar: 🧑‍💼 Kasiyer, 💵 Ödeme, ✅ Onay
 */

// Total revenue tracking
totalRevenue(0).
transactionCount(0).

// Initial goal
!start.

+!start <- 
    .print("═══════════════════════════════════════════════════════");
    .print("🧑‍💼 KASİYER - Kasa hazır!");
    .print("═══════════════════════════════════════════════════════");
    .print("💰 Toplam gelir: $0");
    .print("═══════════════════════════════════════════════════════").

// Moise organizational goal
+!takePayment[scheme(S),source(self)] <-
    .print("🧑‍💼 [ORG] Ready to take payments").

// ========== ÖDEME İŞLEME ==========
+!processPayment(Customer, Amount)[source(S)] <-
    .print("═══════════════════════════════════════════════════════");
    .print("🧑‍💼 [ÖDEME] 💵 Yeni ödeme!");
    .print("🧑‍💼 [ÖDEME] Müşteri: ", Customer);
    .print("🧑‍💼 [ÖDEME] Tutar: $", Amount);
    
    // Record transaction
    processTransaction(Amount);
    
    // Simulate payment processing time
    .print("🧑‍💼 [ÖDEME] ⏳ İşleniyor...");
    .wait(1500);
    
    // Update totals
    ?totalRevenue(R);
    -+totalRevenue(R + Amount);
    ?transactionCount(T);
    -+transactionCount(T + 1);
    
    .print("🧑‍💼 [ÖDEME] ✅ Ödeme tamamlandı!");
    .print("🧑‍💼 [ÖDEME] Toplam gelir: $", R + Amount);
    .print("🧑‍💼 [ÖDEME] İşlem sayısı: ", T + 1);
    .print("═══════════════════════════════════════════════════════");
    
    .send(S, tell, paymentComplete).

// Günlük rapor (opsiyonel)
+!dailyReport <-
    ?totalRevenue(R);
    ?transactionCount(T);
    .print("═══════════════════════════════════════════════════════");
    .print("🧑‍💼 [RAPOR] 📊 Günlük Rapor");
    .print("🧑‍💼 [RAPOR] İşlem sayısı: ", T);
    .print("🧑‍💼 [RAPOR] Toplam gelir: $", R);
    .print("═══════════════════════════════════════════════════════").

{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }
{ include("$moiseJar/asl/org-obedient.asl") }
