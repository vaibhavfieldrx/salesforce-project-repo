public class UpdateActiveCustomersPerTerritory {

    public static void executeLogic() {

        Map<Id, Territory__c> territoryMap = new Map<Id, Territory__c>(
            [SELECT Id, Active_Customer_Count__c FROM Territory__c]
        );

        List<AggregateResult> results = [
            SELECT Territory__c territoryId, COUNT(Id) total
            FROM Account
            WHERE Active__c = 'Yes'
            AND Territory__c != null
            GROUP BY Territory__c
        ];

        for (Territory__c t : territoryMap.values()) {
            t.Active_Customer_Count__c = 0;
        }

        for (AggregateResult ar : results) {
            Id terrId = (Id) ar.get('territoryId');
            Long cnt = (Long) ar.get('total');

            if (territoryMap.containsKey(terrId)) {
                territoryMap.get(terrId).Active_Customer_Count__c = cnt.intValue();
            }
        }

        update territoryMap.values();
    }
}