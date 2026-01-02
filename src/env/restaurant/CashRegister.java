/**
 * CashRegister Artifact - Restaurant Multi-Agent System
 * 
 * 💰 Kasa yönetimi - Ödeme ve gelir takibi
 * 
 * Observable Properties (JaCaMo-Web'de görünür):
 * - totalRevenue: Toplam gelir
 * - transactionCount: İşlem sayısı
 * - lastTransaction: Son işlem tutarı
 * - registerStatus: Durum mesajı (ikonlarla)
 */

package restaurant;

import cartago.*;
import java.util.*;

@ARTIFACT_INFO(outports = { @OUTPORT(name = "out-1") })
public class CashRegister extends Artifact {

    private int totalRevenue;
    private int transactionCount;
    private Map<String, Integer> customerBills; // customerId -> amount

    // Menu prices
    private static final Map<String, Integer> MENU_PRICES = new HashMap<>();
    static {
        MENU_PRICES.put("pizza", 25);
        MENU_PRICES.put("burger", 18);
        MENU_PRICES.put("salad", 12);
        MENU_PRICES.put("pasta", 20);
        MENU_PRICES.put("steak", 45);
    }

    void init() {
        this.totalRevenue = 0;
        this.transactionCount = 0;
        this.customerBills = new HashMap<>();

        defineObsProperty("totalRevenue", 0);
        defineObsProperty("transactionCount", 0);
        defineObsProperty("lastTransaction", 0);
        defineObsProperty("registerStatus", "💰 Register ready");
    }

    /**
     * Müşteri hesabını hesapla
     */
    @OPERATION
    void calculateBill(String customerId, OpFeedbackParam<Integer> amount) {
        // For simplicity, use a default price
        int bill = customerBills.getOrDefault(customerId, 25);
        amount.set(bill);

        getObsProperty("registerStatus").updateValue(
                "💵 Bill for " + customerId + ": $" + bill);
    }

    /**
     * Sipariş fiyatını kaydet
     */
    @OPERATION
    void addToOrder(String customerId, String food) {
        int price = MENU_PRICES.getOrDefault(food, 20);
        int currentBill = customerBills.getOrDefault(customerId, 0);
        customerBills.put(customerId, currentBill + price);

        signal("orderAdded", customerId, food, price);
    }

    /**
     * Ödeme işle
     */
    @OPERATION
    void processTransaction(int amount) {
        totalRevenue += amount;
        transactionCount++;

        getObsProperty("totalRevenue").updateValue(totalRevenue);
        getObsProperty("transactionCount").updateValue(transactionCount);
        getObsProperty("lastTransaction").updateValue(amount);
        getObsProperty("registerStatus").updateValue(
                "✅ Payment: $" + amount + " | Total: $" + totalRevenue);

        signal("transactionComplete", amount, totalRevenue);
    }

    /**
     * Günlük rapor
     */
    @OPERATION
    void getDailyReport(OpFeedbackParam<Integer> revenue, OpFeedbackParam<Integer> transactions) {
        revenue.set(totalRevenue);
        transactions.set(transactionCount);
    }
}
