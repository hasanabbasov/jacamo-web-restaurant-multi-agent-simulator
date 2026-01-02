/**
 * OrderBoard Artifact - Restaurant Multi-Agent System
 * 
 * 📋 Sipariş takip tablosu - JaCaMo-Web'de görsel simülasyon
 * 
 * Bu artifact, mevcut projedeki Counter.java gibi çalışır ama
 * restoran siparişlerini takip eder.
 * 
 * Observable Properties:
 * - activeOrders: Aktif sipariş sayısı
 * - completedOrders: Tamamlanan sipariş sayısı
 * - currentStatus: Güncel durum mesajı (ikonlarla)
 */

package restaurant;

import cartago.*;
import java.util.*;

@ARTIFACT_INFO(outports = { @OUTPORT(name = "out-1") })
public class OrderBoard extends Artifact {

    private List<String> pendingOrders;
    private List<String> cookingOrders;
    private int completedCount;

    void init() {
        pendingOrders = new ArrayList<>();
        cookingOrders = new ArrayList<>();
        completedCount = 0;

        defineObsProperty("activeOrders", 0);
        defineObsProperty("pendingOrders", 0);
        defineObsProperty("cookingOrders", 0);
        defineObsProperty("completedOrders", 0);
        defineObsProperty("currentStatus", "🍽️ Restaurant Ready");
    }

    /**
     * Yeni sipariş kaydı
     */
    @OPERATION
    void recordOrder(String customer, String food) {
        String order = customer + ":" + food;
        pendingOrders.add(order);

        updateCounts();
        getObsProperty("currentStatus").updateValue(
                "📝 New order: " + food + " for " + customer);

        signal("orderRecorded", customer, food);
    }

    /**
     * Pişirme başladı
     */
    @OPERATION
    void startCooking(String food) {
        // Find first matching pending order
        for (int i = 0; i < pendingOrders.size(); i++) {
            if (pendingOrders.get(i).contains(food)) {
                String order = pendingOrders.remove(i);
                cookingOrders.add(order);
                break;
            }
        }

        updateCounts();
        getObsProperty("currentStatus").updateValue(
                "🔥 Cooking: " + food);

        signal("cookingStarted", food);
    }

    /**
     * Pişirme tamamlandı
     */
    @OPERATION
    void finishCooking(String food) {
        // Find first matching cooking order
        for (int i = 0; i < cookingOrders.size(); i++) {
            if (cookingOrders.get(i).contains(food)) {
                cookingOrders.remove(i);
                completedCount++;
                break;
            }
        }

        updateCounts();
        getObsProperty("currentStatus").updateValue(
                "✅ Ready: " + food + " | Total: " + completedCount);

        signal("cookingFinished", food);
    }

    /**
     * Servis yapıldı
     */
    @OPERATION
    void deliverFood(String customer, String food) {
        getObsProperty("currentStatus").updateValue(
                "🍽️ Served: " + food + " to " + customer);
        signal("foodDelivered", customer, food);
    }

    /**
     * Sayaçları güncelle
     */
    private void updateCounts() {
        int total = pendingOrders.size() + cookingOrders.size();
        getObsProperty("activeOrders").updateValue(total);
        getObsProperty("pendingOrders").updateValue(pendingOrders.size());
        getObsProperty("cookingOrders").updateValue(cookingOrders.size());
        getObsProperty("completedOrders").updateValue(completedCount);
    }

    /**
     * Tüm bekleyen siparişleri getir
     */
    @OPERATION
    void getPendingCount(OpFeedbackParam<Integer> count) {
        count.set(pendingOrders.size());
    }
}
