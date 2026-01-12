public class InactiveAccounts implements Database.Batchable<SObject>, Database.Stateful {

    private Date thresholdDate = Date.today().addDays(-30);
    private Map<Id, List<Account>> terrToInactiveAccounts = new Map<Id, List<Account>>();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, CreatedDate, Territory__c
            FROM Account
            WHERE Territory__c != NULL
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {

        Set<Id> accIds = new Set<Id>();
        for (Account acc : scope) accIds.add(acc.Id);

        Map<Id, Date> latestOrderMap = new Map<Id, Date>();

        for (AggregateResult ar : [
            SELECT Account__c accId, MAX(CreatedDate) maxDate
            FROM Order
            WHERE Account__c IN :accIds
            GROUP BY Account__c
        ]) {
            latestOrderMap.put((Id) ar.get('accId'), ((Datetime) ar.get('maxDate')).date());
        }

        for (Account acc : scope) {
            Boolean isInactive = false;

            if (latestOrderMap.containsKey(acc.Id)) {
                if (latestOrderMap.get(acc.Id) <= thresholdDate) isInactive = true;
            } else {
                if (acc.CreatedDate.date() <= thresholdDate) isInactive = true;
            }

            if (isInactive) {
                if (!terrToInactiveAccounts.containsKey(acc.Territory__c)) {
                    terrToInactiveAccounts.put(acc.Territory__c, new List<Account>());
                }
                terrToInactiveAccounts.get(acc.Territory__c).add(acc);
            }
        }
    }

    public void finish(Database.BatchableContext bc) {

        if (terrToInactiveAccounts.isEmpty()) return;

        // Fetch Sales Manager per territory
        Map<Id, Territory__c> terrMap = new Map<Id, Territory__c>(
            [SELECT Id, Sales_Manager__r.Email__c
             FROM Territory__c
             WHERE Id IN :terrToInactiveAccounts.keySet()]
        );

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        // Fetch template
        EmailTemplate template = [
            SELECT Id
            FROM EmailTemplate
            WHERE DeveloperName = 'Inactive_Accounts_Email_Template'
            LIMIT 1
        ];

        for (Id terrId : terrToInactiveAccounts.keySet()) {

            Territory__c terr = terrMap.get(terrId);
            if (terr == null || terr.Sales_Manager__r.Email__c == null) continue;

            // Build account list text
            String accListText = '';
            for (Account a : terrToInactiveAccounts.get(terrId)) {
                accListText += '- ' + a.Name + '\n';
            }

            // Create log record
            Inactive_Accounts_Log__c log = new Inactive_Accounts_Log__c(
                Territory__c = terrId,
                Inactive_List__c = accListText
            );
            insert log;

            // Build email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setTemplateId(template.Id);
            email.setTargetObjectId(UserInfo.getUserId()); // mandatory for template
            email.setWhatId(log.Id);
            email.setToAddresses(new List<String>{ terr.Sales_Manager__r.Email__c });
            email.setSaveAsActivity(false);

            emailsToSend.add(email);
        }

        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
        }
    }
}