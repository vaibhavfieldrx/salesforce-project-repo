@isTest
public class CreateInvoiceOnOrderTest {
    @isTest
    static void testInvoiceCreatedFromAccountEmail() {
        // Create Account with email (change Email__c if your field name differs)
        Account acc = new Account(Name = 'TC Account', Email__c = 'acctest@example.com');
        insert acc;
 
        // Create Order providing required fields: AccountId, EffectiveDate, Status
        Order ord = new Order(
            Name = 'Test Order 1',
            AccountId = acc.Id,
            Status = 'Draft',            // use a valid Status for your org
            EffectiveDate = Date.today()
        );
        insert ord; // trigger runs and should create the Invoice
 
        // Verify invoice created and email copied
        List<Invoice> invs = [SELECT Id, Order__c, Customer_Email__c, Status FROM Invoice WHERE Order__c = :ord.Id];
        System.assertEquals(1, invs.size(), 'Invoice should be created');
        System.assertEquals('acctest@example.com', invs[0].Customer_Email__c);
    }
 
    @isTest
    static void testInvoiceCreatedUsingOrderEmail() {
        Account acc = new Account(Name = 'TC Account 2', Email__c = 'acct2@example.com');
        insert acc;
 
        Order ord = new Order(
            Name = 'Test Order 2',
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Customer_Email__c = 'order@example.com'
        );
        insert ord;
 
        List<Invoice> invs = [SELECT Id, Customer_Email__c FROM Invoice WHERE Order__c = :ord.Id];
        System.assertEquals(1, invs.size());
        System.assertEquals('order@example.com', invs[0].Customer_Email__c);
    }
}