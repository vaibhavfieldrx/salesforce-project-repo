/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-02-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/


// ✅ UI Object API – for metadata & picklist
// ✅ @wire Apex – for reading records
// ✅ Imperative Apex – for create / update / delete


public with sharing class AccountController {
     @AuraEnabled(cacheable=true)
     public static List<Account> getAccounts() {
         return [SELECT Id, Name, Phone, Website FROM Account LIMIT 5];
     }

      @AuraEnabled
    public static Account saveAccount(Account acc) {
        upsert acc;
        return acc;
    }

    @AuraEnabled
    public static string updateAccounts(List<Account> accounts){
            update accounts;
            return 'Accounts updated successfully';
    }

    @AuraEnabled
    public static void deleteAccount(Id accountId) {
        delete [SELECT Id FROM Account WHERE Id = :accountId];
    }
}