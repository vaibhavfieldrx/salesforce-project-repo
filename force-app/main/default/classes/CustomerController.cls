public with sharing class CustomerController {

    @AuraEnabled(cacheable=true)
    public static List<AccountWrapper> getCustomers() {

        List<AccountWrapper> result = new List<AccountWrapper>();

        List<Account> accList = [
            SELECT Id, Name, Phone, 
                (SELECT Id, Name FROM Contacts ORDER BY CreatedDate ASC LIMIT 1)
            FROM Account
            ORDER BY Name
            LIMIT 50
        ];

        for (Account acc : accList) {
            AccountWrapper w = new AccountWrapper();
            w.accountId = acc.Id;
            w.accountName = acc.Name;

            if (!acc.Contacts.isEmpty()) {
                w.contactId = acc.Contacts[0].Id;
            }

            result.add(w);
        }

        return result;
    }

    public class AccountWrapper {
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public Id contactId;
        @AuraEnabled public String Phone;

    }
}
