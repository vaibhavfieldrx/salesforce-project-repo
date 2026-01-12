public class StockExpiryReminderEmailHandler {

    public static void sendExpiryReminders() {
        Date today = Date.today();
        Set<Date> targetDates = new Set<Date>{
            today.addDays(10),
            today.addDays(5),
            today.addDays(1)
        };

        // Fetch expiring stock ledgers and their warehouses
        List<Stock_Ledger__c> expiringLedgers = [
            SELECT Id, Name, Expiry_Date__c, Source__c,
                   Warehouse__c, Warehouse__r.Name
            FROM Stock_Ledger__c
            WHERE Source__c = 'Stock added to Warehouse'
            AND Expiry_Date__c IN :targetDates
        ];

        if (expiringLedgers.isEmpty()) return;

        // Collect warehouse Ids
        Set<Id> warehouseIds = new Set<Id>();
        for (Stock_Ledger__c ledger : expiringLedgers) {
            if (ledger.Warehouse__c != null)
                warehouseIds.add(ledger.Warehouse__c);
        }

        // ️Fetch Territories linked to those Warehouses
        Map<Id, List<Territory__c>> warehouseToTerritories = new Map<Id, List<Territory__c>>();
        Map<Id, Id> territoryToSalesManager = new Map<Id, Id>();

        if (!warehouseIds.isEmpty()) {
            for (Territory__c t : [
                SELECT Id, Name, Warehouse__c, Sales_Manager__c
                FROM Territory__c
                WHERE Warehouse__c IN :warehouseIds
            ]) {
                if (!warehouseToTerritories.containsKey(t.Warehouse__c))
                    warehouseToTerritories.put(t.Warehouse__c, new List<Territory__c>());
                warehouseToTerritories.get(t.Warehouse__c).add(t);

                if (t.Sales_Manager__c != null)
                    territoryToSalesManager.put(t.Id, t.Sales_Manager__c);
            }
        }

        // Fetch all Sales Managers and their Field Executives
        Set<Id> salesManagerIds = new Set<Id>(territoryToSalesManager.values());
        Map<Id, Sales_Manager__c> smMap = new Map<Id, Sales_Manager__c>();
        Map<Id, List<Field_Executive__c>> smToFEs = new Map<Id, List<Field_Executive__c>>();

        if (!salesManagerIds.isEmpty()) {
            smMap = new Map<Id, Sales_Manager__c>([
                SELECT Id, Name, Email__c FROM Sales_Manager__c WHERE Id IN :salesManagerIds
            ]);

            for (Field_Executive__c fe : [
                SELECT Id, Name, Email__c, Sales_Manager__c
                FROM Field_Executive__c
                WHERE Sales_Manager__c IN :salesManagerIds
            ]) {
                if (!smToFEs.containsKey(fe.Sales_Manager__c))
                    smToFEs.put(fe.Sales_Manager__c, new List<Field_Executive__c>());
                smToFEs.get(fe.Sales_Manager__c).add(fe);
            }
        }

        // Get email template
        EmailTemplate template = [
            SELECT Id 
            FROM EmailTemplate 
            WHERE DeveloperName = 'Stock_Expiry_Reminder_Email' 
            LIMIT 1
        ];

        // Build and send emails
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        for (Stock_Ledger__c ledger : expiringLedgers) {
            Set<String> recipients = new Set<String>();

            // Find related territories for this warehouse
            if (warehouseToTerritories.containsKey(ledger.Warehouse__c)) {
                for (Territory__c terr : warehouseToTerritories.get(ledger.Warehouse__c)) {

                    Id smId = terr.Sales_Manager__c;
                    if (smId != null && smMap.containsKey(smId)) {
                        // Sales Manager email
                        if (smMap.get(smId).Email__c != null)
                            recipients.add(smMap.get(smId).Email__c);

                        // Field Executives under this Sales Manager
                        if (smToFEs.containsKey(smId)) {
                            for (Field_Executive__c fe : smToFEs.get(smId)) {
                                if (fe.Email__c != null)
                                    recipients.add(fe.Email__c);
                            }
                        }
                    }
                }
            }

            // Add admin
            recipients.add('rajgauriv@codeplateau.com');

            if (!recipients.isEmpty()) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setTemplateId(template.Id);
                email.setTargetObjectId(UserInfo.getUserId());
                email.setWhatId(ledger.Id);
                email.setToAddresses(new List<String>(recipients));
                email.setSaveAsActivity(false);

                System.debug('Stock: ' + ledger.Name +
                             ' | Warehouse: ' + ledger.Warehouse__r.Name +
                             ' | Expiry: ' + ledger.Expiry_Date__c +
                             ' | Recipients: ' + recipients);

                emailsToSend.add(email);
            }
        }

        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
            System.debug('Sent ' + emailsToSend.size() + ' expiry reminder emails.');
        }
    }
}