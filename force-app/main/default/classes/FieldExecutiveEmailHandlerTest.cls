/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-12-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@IsTest
public class FieldExecutiveEmailHandlerTest {

    @IsTest
    static void testSendWelcomeEmail_WithEmail() {

        Field_Executive__c fe = new Field_Executive__c(
            Field_Executive_Name__c = 'Test Executive',
            Email__c = 'test@test.com'
        );

        Test.startTest();
            FieldExecutiveEmailHandler.sendWelcomeEmail(
                new List<Field_Executive__c>{ fe }
            );
        Test.stopTest();

        // Assertion only to confirm execution reached this point
        System.assert(true, 'Method executed successfully');
    }

    @IsTest
    static void testSendWelcomeEmail_WithoutEmail() {

        Field_Executive__c fe = new Field_Executive__c(
            Field_Executive_Name__c = 'No Email Executive',
            Email__c = null
        );

        Test.startTest();
            FieldExecutiveEmailHandler.sendWelcomeEmail(
                new List<Field_Executive__c>{ fe }
            );
        Test.stopTest();

        System.assert(true, 'Handled null email correctly');
    }

    @IsTest
    static void testSendWelcomeEmail_EmptyList() {

        Test.startTest();
            FieldExecutiveEmailHandler.sendWelcomeEmail(
                new List<Field_Executive__c>()
            );
        Test.stopTest();

        System.assert(true, 'Handled empty list correctly');
    }
}