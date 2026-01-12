@isTest
public class AccountCustomerHandlerTest {

    @isTest
    static void testUniqueEmailPhone() {

        // Insert first account
        Account acc1 = new Account(Name='Customer 1', Email__c='Nitinr@codeplateau.com', Phone='1234567890');
        insert acc1;

        // Insert second account with same email → should fail
        Account acc2 = new Account(Name='Customer 2', Email__c='Nitinr@codeplateau.com', Phone='0987654321');
        try {
            insert acc2;
            System.assert(false, 'Insert should have thrown error due to duplicate email');
        } catch(DmlException e) {
            System.assert(e.getMessage().contains('Email must be unique'));
        }

        // Insert second account with same phone → should fail
        Account acc3 = new Account(Name='Customer 3', Email__c='nrajas.rajas@gmail.com', Phone='1234567890');
        try {
            insert acc3;
            System.assert(false, 'Insert should have thrown error due to duplicate phone');
        } catch(DmlException e) {
            System.assert(e.getMessage().contains('Phone must be unique'));
        }

        // Insert valid unique account → should succeed
        Account acc4 = new Account(Name='Customer 4', Email__c='unique2@example.com', Phone='2223334444');
        insert acc4;
        System.assertNotEquals(null, acc4.Id, 'Account should be inserted successfully');
    }

    @isTest
    static void testUpdateAccountUniqueness() {
        Account acc1 = new Account(Name='Customer A', Email__c='a@example.com', Phone='1111111111');
        Account acc2 = new Account(Name='Customer B', Email__c='b@example.com', Phone='2222222222');
        insert new List<Account>{acc1, acc2};

        // Try to update acc2 email to acc1 email → should fail
        acc2.Email__c = 'a@example.com';
        try {
            update acc2;
            System.assert(false, 'Update should fail due to duplicate email');
        } catch(DmlException e) {
            System.assert(e.getMessage().contains('Email must be unique'));
        }

        // Update phone to unique value → should succeed
        acc2.Phone = '3333333333';
        update acc2;
        System.assertEquals('3333333333', [SELECT Phone FROM Account WHERE Id=:acc2.Id].Phone);
    }
}