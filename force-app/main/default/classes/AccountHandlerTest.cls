@isTest
public class AccountHandlerTest {

    @isTest
    static void simpleTest() {

     
        Credit_Limit_Setting__c cs = new Credit_Limit_Setting__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Credit_Limit__c = 1000
        );
        insert cs;

        Account acc1 = new Account(
            Name = 'Test Account 1',
            Outstanding_Amount__c = 500
        );
        insert acc1;

       
        acc1.Outstanding_Amount__c = 1500;
        update acc1;

       
        Account updatedAcc = [
            SELECT Id, Outstanding_Amount__c, On_Hold__c
            FROM Account
            WHERE Id = :acc1.Id
            LIMIT 1
        ];

    }
}