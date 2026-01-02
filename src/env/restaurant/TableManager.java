/**
 * TableManager Artifact - Restaurant Multi-Agent System
 * 
 * 🪑 Masa yönetimi - Doluluk durumu takibi
 * 
 * Observable Properties (JaCaMo-Web'de görünür):
 * - totalTables: Toplam masa sayısı
 * - occupiedTables: Dolu masa sayısı
 * - availableTables: Boş masa sayısı
 * - tableStatus: Durum mesajı (ikonlarla)
 */

package restaurant;

import cartago.*;
import java.util.*;

@ARTIFACT_INFO(outports = { @OUTPORT(name = "out-1") })
public class TableManager extends Artifact {

    private int totalTables;
    private Map<Integer, String> tableOccupancy; // tableId -> customerId

    void init(int tables) {
        this.totalTables = tables;
        this.tableOccupancy = new HashMap<>();

        defineObsProperty("totalTables", tables);
        defineObsProperty("occupiedTables", 0);
        defineObsProperty("availableTables", tables);
        defineObsProperty("tableStatus", "🪑 All " + tables + " tables available");
    }

    /**
     * Müşteriye masa ata - sadece customerId alır, tableId döner
     */
    @OPERATION
    void assignTable(String customerId) {
        int occupied = tableOccupancy.size();

        if (occupied < totalTables) {
            // Find next available table
            int table = findAvailableTable();
            tableOccupancy.put(table, customerId);

            updateStatus();
            defineObsProperty("lastAssignedTable", table);
            signal("tableAssigned", table, customerId);
        } else {
            failed("No tables available");
        }
    }

    /**
     * Masayı boşalt
     */
    @OPERATION
    void freeTable(String customerId) {
        Integer tableToFree = null;
        for (Map.Entry<Integer, String> entry : tableOccupancy.entrySet()) {
            if (entry.getValue().equals(customerId)) {
                tableToFree = entry.getKey();
                break;
            }
        }

        if (tableToFree != null) {
            tableOccupancy.remove(tableToFree);
            updateStatus();
            signal("tableFreed", tableToFree);
        }
    }

    /**
     * Boş masa bul
     */
    private int findAvailableTable() {
        for (int i = 1; i <= totalTables; i++) {
            if (!tableOccupancy.containsKey(i)) {
                return i;
            }
        }
        return -1;
    }

    /**
     * Durumu güncelle
     */
    private void updateStatus() {
        int occupied = tableOccupancy.size();
        int available = totalTables - occupied;

        getObsProperty("occupiedTables").updateValue(occupied);
        getObsProperty("availableTables").updateValue(available);

        String icon = available > 0 ? "🪑" : "⛔";
        String status = icon + " Tables: " + occupied + "/" + totalTables + " occupied";
        getObsProperty("tableStatus").updateValue(status);
    }

    /**
     * Boş masa var mı kontrol et
     */
    @OPERATION
    void hasAvailableTable(OpFeedbackParam<Boolean> available) {
        available.set(tableOccupancy.size() < totalTables);
    }
}
