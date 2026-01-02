/*
 * Cook Agent - Restaurant Multi-Agent System
 * Rol: Aşçı - yemek hazırlayan
 * Amaç: Siparişleri pişirmek (süreye bağlı)
 * 
 * 🍳 İkonlar: 👨‍🍳 Aşçı, 🔥 Pişirme, ⏱️ Süre
 * 
 * Yemek süreleri (ms) - +10 saniye eklenmiş:
 * - Pizza: 15000ms (15 saniye = 5+10)
 * - Burger: 13000ms (13 saniye = 3+10)
 * - Salad: 12000ms (12 saniye = 2+10)
 * - Pasta: 14000ms (14 saniye = 4+10)
 * - Steak: 17000ms (17 saniye = 7+10)
 */

// Cooking time beliefs (in milliseconds) - +10 SECONDS ADDED
cookingTime(pizza, 15000).
cookingTime(burger, 13000).
cookingTime(salad, 12000).
cookingTime(pasta, 14000).
cookingTime(steak, 17000).

// Currently cooking count
currentlyCooking(0).

// Initial goal
!start.

+!start <- 
    .print("═══════════════════════════════════════════════════════");
    .print("👨‍🍳 AŞÇI - Mutfak hazır!");
    .print("═══════════════════════════════════════════════════════");
    .print("🍕 Pizza: 15 saniye");
    .print("🍔 Burger: 13 saniye");
    .print("🥗 Salad: 12 saniye");
    .print("🍝 Pasta: 14 saniye");
    .print("🥩 Steak: 17 saniye");
    .print("═══════════════════════════════════════════════════════").

// Moise organizational goal
+!cookFood[scheme(S),source(self)] <-
    .print("👨‍🍳 [ORG] Ready to cook").

// ========== YEMEK HAZIRLAMA ==========
+!prepareFood(Customer, Food)[source(waiter)] <-
    .print("═══════════════════════════════════════════════════════");
    .print("👨‍🍳 [PİŞİRME] 🔥 Yeni sipariş geldi!");
    .print("👨‍🍳 [PİŞİRME] Yemek: ", Food);
    .print("👨‍🍳 [PİŞİRME] Müşteri: ", Customer);
    
    // Get cooking time for this food (default 3000ms if not found)
    if (cookingTime(Food, Time)) {
        .print("👨‍🍳 [PİŞİRME] ⏱️ Süre: ", Time/1000, " saniye")
    } else {
        Time = 3000;
        .print("👨‍🍳 [PİŞİRME] ⏱️ Süre: 3 saniye (varsayılan)")
    };
    .print("═══════════════════════════════════════════════════════");
    
    // Update cooking status
    ?currentlyCooking(N);
    -+currentlyCooking(N+1);
    .print("👨‍🍳 [PİŞİRME] Aktif pişirme sayısı: ", N+1);
    startCooking(Food);
    
    // Wait for cooking time
    .print("👨‍🍳 [PİŞİRME] ⏳ Bekleniyor...");
    .wait(Time);
    
    // Cooking complete
    finishCooking(Food);
    ?currentlyCooking(M);
    -+currentlyCooking(M-1);
    
    .print("═══════════════════════════════════════════════════════");
    .print("👨‍🍳 [HAZIR] ✅ ", Food, " hazır!");
    .print("👨‍🍳 [HAZIR] Müşteri: ", Customer);
    .print("═══════════════════════════════════════════════════════");
    
    .send(waiter, tell, foodReady(Customer, Food)).

// Bilinmeyen yemek için fallback
-!prepareFood(Customer, Food) <-
    .print("👨‍🍳 [HATA] ❌ Yemek hazırlanamadı: ", Food);
    .send(waiter, tell, foodFailed(Customer, Food)).

{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }
{ include("$moiseJar/asl/org-obedient.asl") }
