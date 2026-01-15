/**
 * OrderBoard Artifact - Restaurant Multi-Agent System
 * 
 * 📋 Blackboard Pattern ile Öncelikli Sipariş Kuyruğu
 * 
 * Siparişler değer puanına göre sıralanır:
 * Değer Puanı = Fiyat / Pişirme Süresi
 * 
 * En yüksek değer puanlı sipariş önce hazırlanır.
 */

package restaurant;

import cartago.*;
import java.util.*;

@ARTIFACT_INFO(outports = { @OUTPORT(name = "out-1") })
public class OrderBoard extends Artifact {

    // Fiyat tablosu
    private static final Map<String, Integer> PRICES = new HashMap<>();
    // Pişirme süresi tablosu (saniye)
    private static final Map<String, Integer> COOK_TIMES = new HashMap<>();

    static {
        PRICES.put("pizza", 25);
        PRICES.put("burger", 18);
        PRICES.put("salad", 12);
        PRICES.put("pasta", 20);
        PRICES.put("steak", 45);

        COOK_TIMES.put("pizza", 15);
        COOK_TIMES.put("burger", 13);
        COOK_TIMES.put("salad", 12);
        COOK_TIMES.put("pasta", 14);
        COOK_TIMES.put("steak", 17);
    }

    // Sipariş sınıfı
    private static class Order implements Comparable<Order> {
        String customer;
        String food;
        int price;
        int cookTime;
        double valueScore;
        long timestamp;

        Order(String customer, String food) {
            this.customer = customer;
            this.food = food;
            this.price = PRICES.getOrDefault(food, 15);
            this.cookTime = COOK_TIMES.getOrDefault(food, 10);
            this.valueScore = (double) price / cookTime;
            this.timestamp = System.currentTimeMillis();
        }

        @Override
        public int compareTo(Order other) {
            // Yüksek değer puanı önce (descending)
            int cmp = Double.compare(other.valueScore, this.valueScore);
            if (cmp == 0) {
                // Eşitse erken gelen önce
                return Long.compare(this.timestamp, other.timestamp);
            }
            return cmp;
        }

        String toKey() {
            return customer + ":" + food;
        }

        @Override
        public String toString() {
            return String.format("%s:%s (%.2f)", customer, food, valueScore);
        }
    }

    private PriorityQueue<Order> pendingOrders;
    private List<Order> cookingOrders;
    private int completedCount;

    void init() {
        pendingOrders = new PriorityQueue<>();
        cookingOrders = new ArrayList<>();
        completedCount = 0;

        defineObsProperty("activeOrders", 0);
        defineObsProperty("pendingOrders", 0);
        defineObsProperty("cookingOrders", 0);
        defineObsProperty("completedOrders", 0);
        defineObsProperty("currentStatus", "🍽️ Restaurant Ready");
        defineObsProperty("pendingOrdersList", "[]");
    }

    /**
     * Yeni sipariş kaydı - öncelik kuyruğuna ekler
     */
    @OPERATION
    void recordOrder(String customer, String food) {
        Order order = new Order(customer, food);
        pendingOrders.add(order);

        System.out.println("[OrderBoard] 📝 Yeni sipariş: " + order);
        System.out.println("[OrderBoard] 📊 Kuyruk sırası: " + getPendingOrdersJson());

        updateCounts();
        updatePendingList();
        getObsProperty("currentStatus").updateValue(
                "📝 New order: " + food + " ($" + order.price + ") - Score: " +
                        String.format("%.2f", order.valueScore));

        signal("orderRecorded", customer, food);
    }

    /**
     * En yüksek öncelikli siparişi döndür
     */
    @OPERATION
    void getNextOrder(OpFeedbackParam<String> customer, OpFeedbackParam<String> food) {
        if (pendingOrders.isEmpty()) {
            customer.set("");
            food.set("");
            return;
        }

        Order next = pendingOrders.peek();
        customer.set(next.customer);
        food.set(next.food);

        System.out.println("[OrderBoard] 🎯 Sonraki sipariş: " + next);
    }

    /**
     * Pişirme başladı - en yüksek öncelikli siparişi al
     */
    @OPERATION
    void startCooking(String food) {
        System.out.println("[OrderBoard] startCooking called with: " + food);

        Order found = null;
        for (Order order : pendingOrders) {
            if (order.food.equals(food)) {
                found = order;
                break;
            }
        }

        if (found != null) {
            pendingOrders.remove(found);
            cookingOrders.add(found);
            System.out.println("[OrderBoard] ✅ Pişirmeye alındı: " + found);
        } else {
            System.out.println("[OrderBoard] ⚠️ Sipariş bulunamadı: " + food);
        }

        updateCounts();
        updatePendingList();
        getObsProperty("currentStatus").updateValue("🔥 Cooking: " + food);

        signal("cookingStarted", food);
    }

    /**
     * Pişirme tamamlandı
     */
    @OPERATION
    void finishCooking(String food) {
        Order found = null;
        for (Order order : cookingOrders) {
            if (order.food.equals(food)) {
                found = order;
                break;
            }
        }

        if (found != null) {
            cookingOrders.remove(found);
            completedCount++;
            System.out.println("[OrderBoard] ✅ Tamamlandı: " + found);
        }

        updateCounts();
        updatePendingList();
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
     * Bekleyen siparişleri JSON formatında güncelle
     */
    private void updatePendingList() {
        getObsProperty("pendingOrdersList").updateValue(getPendingOrdersJson());
    }

    /**
     * Bekleyen siparişleri JSON olarak döndür
     */
    private String getPendingOrdersJson() {
        StringBuilder sb = new StringBuilder("[");
        List<Order> sorted = new ArrayList<>(pendingOrders);
        Collections.sort(sorted);

        for (int i = 0; i < sorted.size(); i++) {
            Order o = sorted.get(i);
            if (i > 0)
                sb.append(",");
            sb.append(String.format(
                    "{\"customer\":\"%s\",\"food\":\"%s\",\"price\":%d,\"cookTime\":%d,\"score\":%.2f}",
                    o.customer, o.food, o.price, o.cookTime, o.valueScore));
        }
        sb.append("]");
        return sb.toString();
    }

    /**
     * Bekleyen sipariş sayısını getir
     */
    @OPERATION
    void getPendingCount(OpFeedbackParam<Integer> count) {
        count.set(pendingOrders.size());
    }
}
