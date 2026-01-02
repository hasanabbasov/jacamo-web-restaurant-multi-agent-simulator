/**
 * Kitchen Artifact - Restaurant Multi-Agent System
 * 
 * 👨‍🍳 Mutfak yönetimi - Pişirme süresi ve kapasite kontrolü
 * 
 * Bu artifact mutfağın durumunu takip eder:
 * - Aynı anda kaç yemek pişiyor
 * - Kuyrukta bekleyen siparişler
 * - Mutfak kapasitesi
 * 
 * Observable Properties (JaCaMo-Web'de görünür):
 * - currentlyCooking: Şu an pişen yemek sayısı
 * - maxCapacity: Maksimum eşzamanlı pişirme
 * - queueSize: Kuyrukta bekleyen sayısı
 * - kitchenStatus: Durum mesajı (ikonlarla)
 */

package restaurant;

import cartago.*;

@ARTIFACT_INFO(outports = { @OUTPORT(name = "out-1") })
public class Kitchen extends Artifact {

    private int maxCapacity;
    private int currentCooking;

    void init(int capacity) {
        this.maxCapacity = capacity;
        this.currentCooking = 0;

        defineObsProperty("currentlyCooking", 0);
        defineObsProperty("maxCapacity", capacity);
        defineObsProperty("queueSize", 0);
        defineObsProperty("kitchenStatus", "👨‍🍳 Kitchen idle");
    }

    /**
     * Pişirme başlat
     */
    @OPERATION
    void startCooking(String food) {
        currentCooking++;
        getObsProperty("currentlyCooking").updateValue(currentCooking);

        String status = "🔥 Cooking " + currentCooking + "/" + maxCapacity + ": " + food;
        getObsProperty("kitchenStatus").updateValue(status);

        signal("cookingStarted", food, currentCooking);
    }

    /**
     * Pişirme bitir
     */
    @OPERATION
    void finishCooking(String food) {
        currentCooking = Math.max(0, currentCooking - 1);
        getObsProperty("currentlyCooking").updateValue(currentCooking);

        String status = currentCooking > 0
                ? "✅ Done: " + food + " | Still cooking: " + currentCooking
                : "👨‍🍳 Kitchen idle";
        getObsProperty("kitchenStatus").updateValue(status);

        signal("cookingFinished", food, currentCooking);
    }

    /**
     * Mutfak durumunu kontrol et
     */
    @OPERATION
    void isKitchenBusy(OpFeedbackParam<Boolean> busy) {
        busy.set(currentCooking >= maxCapacity);
    }

    /**
     * Mevcut pişirme sayısını al
     */
    @OPERATION
    void getCookingCount(OpFeedbackParam<Integer> count) {
        count.set(currentCooking);
    }
}
