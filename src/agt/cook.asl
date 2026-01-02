/*
 * Cook Agent - Restaurant Multi-Agent System
 * Rol: Aşçı - yemek hazırlayan
 * Amaç: Siparişleri pişirmek (süreye bağlı)
 * 
 * 🍳 İkonlar: 👨‍🍳 Aşçı, 🔥 Pişirme, ⏱️ Süre
 * 
 * Yemek süreleri (ms):
 * - Pizza: 5000ms (5 saniye)
 * - Burger: 3000ms (3 saniye)
 * - Salad: 2000ms (2 saniye)
 * - Pasta: 4000ms (4 saniye)
 * - Steak: 7000ms (7 saniye)
 */

// Cooking time beliefs (in milliseconds)
cookingTime(pizza, 5000).
cookingTime(burger, 3000).
cookingTime(salad, 2000).
cookingTime(pasta, 4000).
cookingTime(steak, 7000).

// Currently cooking count
currentlyCooking(0).

// Initial goal
!start.

+!start <- 
    .print("═══════════════════════════════════════════════════════");
    .print("👨‍🍳 AŞÇI - Mutfak hazır!");
    .print("═══════════════════════════════════════════════════════");
    .print("🍕 Pizza: 5 saniye");
    .print("🍔 Burger: 3 saniye");
    .print("🥗 Salad: 2 saniye");
    .print("🍝 Pasta: 4 saniye");
    .print("🥩 Steak: 7 saniye");
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
