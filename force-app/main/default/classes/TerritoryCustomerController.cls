public with sharing class TerritoryCustomerController {

    @AuraEnabled(cacheable=true)
    public static List<TerritoryWrapper> getTerritoryCustomers() {

        /* ================= TERRITORIES ================= */

        List<Territory__c> territories = [
            SELECT
                Id,
                Name,
                Region__c,
                Owner.Name,
                Status_Is_Active__c
            FROM Territory__c
            WHERE Status_Is_Active__c = true
            ORDER BY Name
        ];

        if (territories.isEmpty()) {
            return new List<TerritoryWrapper>();
        }

        Map<Id, TerritoryWrapper> territoryMap = new Map<Id, TerritoryWrapper>();

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

        /* ================= ACCOUNTS ================= */

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
            ORDER BY Name
        ];

        for (Account acc : accounts) {

            TerritoryWrapper territory = territoryMap.get(acc.Territory__c);
            if (territory == null) continue;

            territory.customers.add(
                new CustomerWrapper(
                    acc.Id,
                    acc.Name,
                    acc.Email__c,
                    acc.Phone,
                    acc.Active__c,          // Yes / No picklist
                    territory.territoryName,
                    buildAddress(acc)
                )
            );
        }

        return territoryMap.values();
    }

    /* ================= HELPERS ================= */

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

    /* ================= WRAPPERS ================= */

    public class TerritoryWrapper {
        @AuraEnabled public Id territoryId;
        @AuraEnabled public String territoryName;
        @AuraEnabled public String region;
        @AuraEnabled public String manager;
        @AuraEnabled public List<CustomerWrapper> customers;

        public TerritoryWrapper(
            Id territoryId,
            String territoryName,
            String region,
            String manager
        ) {
            this.territoryId = territoryId;
            this.territoryName = territoryName;
            this.region = region;
            this.manager = manager;
            this.customers = new List<CustomerWrapper>();
        }
    }

    public class CustomerWrapper {
        @AuraEnabled public Id accountId;
        @AuraEnabled public String name;
        @AuraEnabled public String email;
        @AuraEnabled public String phone;
        @AuraEnabled public String activeFlag; // Yes / No
        @AuraEnabled public String territory;
        @AuraEnabled public String address;

        public CustomerWrapper(
            Id accountId,
            String name,
            String email,
            String phone,
            String activeFlag,
            String territory,
            String address
        ) {
            this.accountId = accountId;
            this.name = name;
            this.email = email;
            this.phone = phone;
            this.activeFlag = activeFlag;
            this.territory = territory;
            this.address = address;
        }
    }
}