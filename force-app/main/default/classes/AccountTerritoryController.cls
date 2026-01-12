public class AccountTerritoryController {
    
    @AuraEnabled(cacheable=true)
    public static List<Territory__c> getTerritories() {
        return [
            SELECT Id, Name, State__c, City__c
            FROM Territory__c
            WHERE Status_Is_Active__c = true
            ORDER BY Name
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> getAccountsByTerritory(Id territoryId) {
        return [
            SELECT Id, Name, Phone, Email__c, AccountSource, Type, Field_Executive__c, Industry, Rating,
                   Owner.Name, AnnualRevenue, Territory__c
            FROM Account
            WHERE Territory__c = :territoryId
            ORDER BY Name
        ];
    }
}