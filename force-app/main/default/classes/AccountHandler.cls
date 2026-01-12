public with sharing class AccountHandler {
    public static void evaluateOnHold(List<Account> newList, Map<Id, Account> oldMap) {
        Credit_Limit_Setting__c cs = Credit_Limit_Setting__c.getOrgDefaults();
        Decimal creditLimit = (cs != null && cs.Credit_Limit__c != null) ? cs.Credit_Limit__c : 0;

        for (Account a : newList) {
            if (a.Outstanding_Amount__c == null) continue;

            if (oldMap != null && oldMap.containsKey(a.Id)) {
                Account oldAcc = oldMap.get(a.Id);
                if (oldAcc.Outstanding_Amount__c == a.Outstanding_Amount__c) continue;
            }
            a.On_Hold__c = (a.Outstanding_Amount__c > creditLimit);
        }
    }
}