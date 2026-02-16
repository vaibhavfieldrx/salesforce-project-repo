@IsTest
public class FieldExecutiveEmailTriggerTest {

    @IsTest
    static void testWelcomeEmailSent_OnInsert() {

        // ✅ Create Field Executive WITHOUT Name
        Field_Executive__c fe = new Field_Executive__c(
            Email__c = 'testexecutive@test.com'
        );

        Test.startTest();
        insert fe; 
        Test.stopTest();

        System.assert(
            Limits.getEmailInvocations() > 0,
            'Welcome email should be sent on Field Executive insert'
        );
    }

    @IsTest
    static void testBulkInsert_FieldExecutives() {

        List<Field_Executive__c> feList = new List<Field_Executive__c>();

        for (Integer i = 0; i < 3; i++) {
            feList.add(new Field_Executive__c(
                Email__c = 'exec' + i + '@test.com'
            ));
        }

        Test.startTest();
        insert feList;
        Test.stopTest();

        System.assert(
            Limits.getEmailInvocations() > 0,
            'Emails should be sent for bulk insert'
        );
    }
}
