/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-12-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class OrderManagementController {

  @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDashboardData() {

        // 1️⃣ Latest 50 orders (table)
        List<Order> orders = [
            SELECT Id, OrderNumber, Status, TotalAmount, EffectiveDate,
                   Account.Name
            FROM Order
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];

        // 2️⃣ Overall status summary (NO LIMIT)
        Map<String, Integer> summary = new Map<String, Integer>();
        for (AggregateResult ar : [
            SELECT Status status, COUNT(Id) cnt
            FROM Order
            GROUP BY Status
        ]) {
            summary.put((String) ar.get('status'), (Integer) ar.get('cnt'));
        }

        // 3️⃣ Total Revenue (overall)
        Decimal revenue = 0;
        AggregateResult ar = [
            SELECT SUM(TotalAmount) total
            FROM Order
            WHERE Status != 'Draft'
        ];
        if (ar.get('total') != null) {
            revenue = (Decimal) ar.get('total');
        }

        return new Map<String, Object>{
            'orders' => orders,
            'summary' => summary,
            'revenue' => revenue
        };
    }
}