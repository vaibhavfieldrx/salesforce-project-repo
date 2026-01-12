public with sharing class TerritoryCustomerController {

    @AuraEnabled(cacheable=true)
    public static List<TerritoryWrapper> getTerritoryCustomers() {

        // 🔹 Fetch Active Territories
        List<Territory__c> territories = [
            SELECT
                Id,
                Name,
                Region__c,
                Owner.Name,
                Sales_Manager__c,
                Status_Is_Active__c
            FROM Territory__c
            WHERE Status_Is_Active__c = true
        ];

        if (territories.isEmpty()) {
            return new List<TerritoryWrapper>();
        }

        Map<Id, TerritoryWrapper> territoryMap = new Map<Id, TerritoryWrapper>();

        // 🔹 Initialize Territory Wrappers
        for (Territory__c t : territories) {
            territoryMap.put(
                t.Id,
                new TerritoryWrapper(
                    t.Id,
                    t.Name,
                    t.Region__c,
                    t.Owner != null ? t.Owner.Name : 'N/A'
                )
            );
        }

        // 🔹 Fetch Accounts linked to Territories
        List<Account> accounts = [
            SELECT
                Id,
                Name,
                Email__c,
                Phone,
                Active__c,
                Territory__c,
                BillingStreet,
                BillingCity,
                BillingState,
                BillingCountry
            FROM Account
            WHERE Territory__c IN :territoryMap.keySet()
        ];

        // 🔹 Map Accounts → Territories
        for (Account acc : accounts) {

            TerritoryWrapper wrapper = territoryMap.get(acc.Territory__c);
            if (wrapper == null) continue;

            wrapper.customers.add(
                new CustomerWrapper(
                    acc.Id,
                    acc.Name,
                    acc.Email__c,
                    acc.Phone,
                    acc.Active__c,
                    wrapper.territoryName,
                    buildAddress(acc)
                )
            );
        }

        return territoryMap.values();
    }

    // ================= HELPERS =================

    private static String buildAddress(Account acc) {
        List<String> parts = new List<String>();

        if (String.isNotBlank(acc.BillingStreet)) {
            parts.add(acc.BillingStreet);
        }
        if (String.isNotBlank(acc.BillingCity)) {
            parts.add(acc.BillingCity);
        }
        if (String.isNotBlank(acc.BillingState)) {
            parts.add(acc.BillingState);
        }
        if (String.isNotBlank(acc.BillingCountry)) {
            parts.add(acc.BillingCountry);
        }

        return String.join(parts, ', ');
    }

    // ================= WRAPPERS =================

    public class TerritoryWrapper {
        @AuraEnabled public Id territoryId;
        @AuraEnabled public String territoryName;
        @AuraEnabled public String region;
        @AuraEnabled public String manager;
        @AuraEnabled public List<CustomerWrapper> customers = new List<CustomerWrapper>();

        public TerritoryWrapper(Id id, String name, String reg, String mgr) {
            territoryId = id;
            territoryName = name;
            region = reg;
            manager = mgr;
        }
    }

    public class CustomerWrapper {
        @AuraEnabled public Id accountId;
        @AuraEnabled public String name;
        @AuraEnabled public String email;
        @AuraEnabled public String phone;
        @AuraEnabled public String status;
        @AuraEnabled public String territory;
        @AuraEnabled public String address;

        public CustomerWrapper(
            Id id,
            String n,
            String e,
            String p,
            String active,
            String t,
            String addr
        ) {
            accountId = id;
            name = n;
            email = e;
            phone = p;
            status = active;
            territory = t;
            address = addr;
        }
    }
}