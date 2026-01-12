public class UpdateFEManagerOnTerritoryChangeHandler {
    public static void updateSalesManager(List<Field_Executive__c> newFEs, Map<Id, Field_Executive__c> oldMap) {
        // Get FE Ids where Territory changed
        Set<Id> changedFETerritories = new Set<Id>();
        Map<Id, Id> feToNewTerritory = new Map<Id, Id>();

        for (Field_Executive__c fe : newFEs) {
            Field_Executive__c oldFE = oldMap.get(fe.Id);
            if (fe.Assigned_Territory__c != oldFE.Assigned_Territory__c) {
                feToNewTerritory.put(fe.Id, fe.Assigned_Territory__c);
                changedFETerritories.add(fe.Assigned_Territory__c);
            }
        }

        if (!changedFETerritories.isEmpty()) {
            // Query new Territory's SM
            Map<Id, Territory__c> territories = new Map<Id, Territory__c>(
                [SELECT Id, Sales_Manager__c FROM Territory__c WHERE Id IN :changedFETerritories]
            );

            // Update FE Sales Manager based on new territory
            for (Field_Executive__c fe : newFEs) {
                if (feToNewTerritory.containsKey(fe.Id)) {
                    Id newTerritoryId = feToNewTerritory.get(fe.Id);
                    if (territories.containsKey(newTerritoryId)) {
                        fe.Sales_Manager__c = territories.get(newTerritoryId).Sales_Manager__c;
                    }
                }
            }
        }
    }
}