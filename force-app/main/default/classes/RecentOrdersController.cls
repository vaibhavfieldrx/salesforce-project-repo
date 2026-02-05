public with sharing class RecentOrdersController {
    @AuraEnabled(cacheable=true)
    public static List<Order__c> getRecentOrders() {
        return [
            SELECT Id, Name, Account__r.Name, Amount__c, Status__c
            FROM Order__c
            ORDER BY CreatedDate DESC
            LIMIT 5
        ];
    }
}
