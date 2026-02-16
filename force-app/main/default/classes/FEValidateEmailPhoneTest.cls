@IsTest
public class FEValidateEmailPhoneTest {

    @IsTest
    static void testUniqueEmailAndPhone_Insert() {
        // 1️⃣ Create a Territory record for lookup
        Territory__c terr = new Territory__c(
            City__c = 'Ahmedabad',
            State__c = 'Gujarat',
            Region__c = 'West',
            Status_Is_Active__c = true
        );
        insert terr;

        // 2️⃣ Insert first Field Executive
        Field_Executive__c fe1 = new Field_Executive__c(
            Field_Executive_Name__c = 'FE One',
            Email__c = 'feone@example.com',
            Phone__c = '+91-9876543210',
            Country__c = 'India',           
            State_Province__c = 'Gujarat',  
            City__c = 'Ahmedabad',
            Zip_Postal_Code__c = 380001,
            Assigned_Territory__c = terr.Id 
        );
        insert fe1;

        // 3️⃣ Attempt to insert duplicate email
        Field_Executive__c fe2 = new Field_Executive__c(
            Field_Executive_Name__c = 'FE Two',
            Email__c = 'feone@example.com',
            Phone__c = '9876543211',
            Country__c = 'India',
            State_Province__c = 'Gujarat',
            City__c = 'Ahmedabad',
            Zip_Postal_Code__c = 380002,
            Assigned_Territory__c = terr.Id
        );

        // 4️⃣ Attempt to insert duplicate phone
        Field_Executive__c fe3 = new Field_Executive__c(
            Field_Executive_Name__c = 'FE Three',
            Email__c = 'fethree@example.com',
            Phone__c = '09876543210',
            Country__c = 'India',
            State_Province__c = 'Gujarat',
            City__c = 'Ahmedabad',
            Zip_Postal_Code__c = 380003,
            Assigned_Territory__c = terr.Id
        );

        // 5️⃣ Expect validation error
        try {
            insert new List<Field_Executive__c>{fe2, fe3};
            System.assert(false, 'Expected DMLException due to duplicate email/phone');
        } catch (DmlException ex) {
            System.assert(
                ex.getMessage().contains('Email already exists') ||
                ex.getMessage().contains('Phone number already exists'),
                'Duplicate validation message should be thrown'
            );
        }
    }

    @IsTest
    static void testUniqueEmailAndPhone_Update() {
        // Create Territory
        Territory__c terr = new Territory__c(
            City__c = 'Ahmedabad',
            State__c = 'Gujarat',
            Region__c = 'West',
            Status_Is_Active__c = true
        );
        insert terr;

        // Insert two Field Executives
        Field_Executive__c fe1 = new Field_Executive__c(
            Field_Executive_Name__c = 'FE One',
            Email__c = 'feone@example.com',
            Phone__c = '9876543210',
            Country__c = 'India',
            State_Province__c = 'Gujarat',
            City__c = 'Ahmedabad',
            Zip_Postal_Code__c = 380001,
            Assigned_Territory__c = terr.Id
        );

        Field_Executive__c fe2 = new Field_Executive__c(
            Field_Executive_Name__c = 'FE Two',
            Email__c = 'fetwo@example.com',
            Phone__c = '9876543211',
            Country__c = 'India',
            State_Province__c = 'Gujarat',
            City__c = 'Ahmedabad',
            Zip_Postal_Code__c = 380002,
            Assigned_Territory__c = terr.Id
        );

        insert new List<Field_Executive__c>{fe1, fe2};

        // Attempt to update with duplicate values
        fe2.Email__c = 'feone@example.com';
        fe2.Phone__c = '9876543210';

        try {
            update fe2;
            System.assert(false, 'Expected DMLException due to duplicate email/phone');
        } catch (DmlException ex) {
            System.assert(
                ex.getMessage().contains('Email already exists') ||
                ex.getMessage().contains('Phone number already exists'),
                'Duplicate validation message should be thrown'
            );
        }
    }

    @IsTest
    static void testValidInsert() {
        // Create Territory
        Territory__c terr = new Territory__c(
            City__c = 'Ahmedabad',
            State__c = 'Gujarat',
            Region__c = 'West',
            Status_Is_Active__c = true
        );
        insert terr;

        // Valid Field Executive
        Field_Executive__c fe = new Field_Executive__c(
            Field_Executive_Name__c = 'Unique FE',
            Email__c = 'unique@example.com',
            Phone__c = '9123456789',
            Country__c = 'India',
            State_Province__c = 'Gujarat',
            City__c = 'Ahmedabad',
            Zip_Postal_Code__c = 380003,
            Assigned_Territory__c = terr.Id
        );

        Test.startTest();
        insert fe;
        Test.stopTest();

        Field_Executive__c insertedFE = [
            SELECT Email__c, Phone__c
            FROM Field_Executive__c
            WHERE Id = :fe.Id
        ];

        System.assertEquals('unique@example.com', insertedFE.Email__c);
        System.assertEquals('9123456789', insertedFE.Phone__c);
    }
}
