/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-21-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class OrderManagementController {

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDashboardData(
        Integer pageSize,
        Integer pageNumber
    ) {
        Integer offsetVal = (pageNumber - 1) * pageSize;

        // 1️⃣ Orders with pagination
        List<Order> orders = [
            SELECT Id, OrderNumber, Status, TotalAmount, EffectiveDate,
                   Account.Name
            FROM Order
            ORDER BY CreatedDate DESC
            LIMIT :pageSize
            OFFSET :offsetVal
        ];

        // 2️⃣ Total orders count (for pagination)
        Integer totalOrders = [
            SELECT COUNT()
            FROM Order
        ];

        // 3️⃣ Status summary
        Map<String, Integer> summary = new Map<String, Integer>();
        for (AggregateResult ar : [
            SELECT Status status, COUNT(Id) cnt
            FROM Order
            GROUP BY Status
        ]) {
            summary.put(
                (String) ar.get('status'),
                (Integer) ar.get('cnt')
            );
        }

        // 4️⃣ Total revenue
        Decimal revenue = 0;
        AggregateResult rev = [
            SELECT SUM(TotalAmount) total
            FROM Order
            WHERE Status != 'Draft'
        ];
        if (rev.get('total') != null) {
            revenue = (Decimal) rev.get('total');
        }

        return new Map<String, Object>{
            'orders' => orders,
            'summary' => summary,
            'revenue' => revenue,
            'totalOrders' => totalOrders
        };
    }


 @AuraEnabled(cacheable=true)
public static List<Account> getCustomers() {
    return [
        SELECT Id, Name
        FROM Account
        ORDER BY Name
        LIMIT 200
    ];
}

@AuraEnabled(cacheable=true)
public static Account getCustomerDetails(Id customerId) {
    return [
        SELECT Name, Phone, Email__c
        FROM Account
        WHERE Id = :customerId
        LIMIT 1
    ];
}   
}