/*
 * Cook Agent - Restaurant Multi-Agent System
 * Rol: Aşçı - yemek hazırlayan
 * Amaç: Öncelik kuyruğundan siparişleri TEK TEK pişirmek
 * 
 * 🍳 İkonlar: 👨‍🍳 Aşçı, 🔥 Pişirme, ⏱️ Süre
 * 
 * BLACKBOARD PATTERN:
 * - Cook, OrderBoard kuyruğunu kontrol eder
 * - En yüksek değer puanlı siparişi alır ve pişirir
 * - BİR SİPARİŞ BİTMEDEN YENİSİNE BAŞLAMAZ
 */

// Cooking time beliefs (in milliseconds)
cookingTime(pizza, 15000).
cookingTime(burger, 13000).
cookingTime(salad, 12000).
cookingTime(pasta, 14000).
cookingTime(steak, 17000).

// Initial goal
!start.

+!start <- 
    .print("═══════════════════════════════════════════════════════");
    .print("👨‍🍳 AŞÇI - Mutfak hazır!");
    .print("═══════════════════════════════════════════════════════");
    .print("🍕 Pizza: 15s | 🍔 Burger: 13s | 🥗 Salad: 12s");
    .print("🍝 Pasta: 14s | 🥩 Steak: 17s");
    .print("═══════════════════════════════════════════════════════");
    .print("👨‍🍳 [KUYRUK] Sipariş kuyruğunu dinlemeye başlıyorum...");
    !processOrders.

// Moise organizational goal
+!cookFood[scheme(S),source(self)] <-
    .print("👨‍🍳 [ORG] Ready to cook").

// ========== ANA DÖNGÜ - SENKRON İŞLEME ==========
// Bu plan: kuyruktan al -> pişir (bekle) -> tekrar kontrol et
+!processOrders <-
    // Kuyruktan sonraki siparişi al
    getNextOrder(Customer, Food);
    
    if (Food \== "") {
        // Sipariş var - pişir VE BİTMESİNİ BEKLE
        .print("═══════════════════════════════════════════════════════");
        .print("👨‍🍳 [KUYRUK] 🎯 En yüksek öncelikli sipariş alındı!");
        .print("👨‍🍳 [KUYRUK] Müşteri: ", Customer);
        .print("👨‍🍳 [KUYRUK] Yemek: ", Food);
        .print("═══════════════════════════════════════════════════════");
        
        // Bu çağrı BLOKLAYICI - pişirme bitene kadar bekler
        !cookFood(Customer, Food);
        
        // Pişirme bitti, hemen sonraki siparişe geç
        !processOrders
    } else {
        // Kuyruk boş - 2 saniye bekle ve tekrar kontrol et
        .print("👨‍🍳 [KUYRUK] Bekleyen sipariş yok, 2 saniye sonra kontrol...");
        .wait(2000);
        !processOrders
    }.

// ========== YEMEK PİŞİRME (BLOKLAYICI) ==========
+!cookFood(Customer, Food) <-
    // Convert string to atom for belief lookup
    .term2string(FoodAtom, Food);
    
    // Get cooking time
    if (cookingTime(FoodAtom, Time)) {
        .print("👨‍🍳 [PİŞİRME] ⏱️ Süre: ", Time/1000, " saniye")
    } else {
        Time = 10000;
        .print("👨‍🍳 [PİŞİRME] ⏱️ Süre: 10 saniye (varsayılan for ", Food, ")")
    };
    
    // Update OrderBoard - pending -> cooking
    .print("👨‍🍳 [PİŞİRME] 🔥 Pişirme başlıyor: ", Food);
    startCooking(Food);
    kitchenStartCooking(Food);
    
    // BEKLE - pişirme süresi boyunca bu plan bloklanır
    .print("👨‍🍳 [PİŞİRME] ⏳ Pişiriliyor...");
    .wait(Time);
    
    // Cooking complete
    finishCooking(Food);
    kitchenFinishCooking(Food);
    
    .print("═══════════════════════════════════════════════════════");
    .print("👨‍🍳 [HAZIR] ✅ ", Food, " hazır!");
    .print("👨‍🍳 [HAZIR] Müşteri: ", Customer);
    .print("═══════════════════════════════════════════════════════");
    
    // Notify waiter
    .send(waiter, tell, foodReady(Customer, Food)).

// ========== HATA YÖNETİMİ ==========
-!cookFood(Customer, Food) <-
    .print("👨‍🍳 [HATA] ❌ Yemek hazırlanamadı: ", Food);
    .send(waiter, tell, foodFailed(Customer, Food)).

-!processOrders <-
    .print("👨‍🍳 [HATA] Kuyruk işleme hatası - 3 saniye sonra tekrar...");
    .wait(3000);
    !processOrders.

{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }
{ include("$moiseJar/asl/org-obedient.asl") }
