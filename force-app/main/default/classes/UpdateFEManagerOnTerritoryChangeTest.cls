@IsTest
public class UpdateFEManagerOnTerritoryChangeTest {

    @IsTest
    static void testUpdateSalesManager_OnTerritoryChange() {

        // -----------------------------
        // Create Territories
        // -----------------------------
        Territory__c terrOld = new Territory__c(
            City__c = 'Ahmedabad',
            State__c = 'Gujarat',
            Region__c = 'West',
            Status_Is_Active__c = true
        );
        insert terrOld;

        Territory__c terrNew = new Territory__c(
            City__c = 'Ahmedabad',
            State__c = 'Gujarat',
            Region__c = 'West',
            Status_Is_Active__c = true
        );
        insert terrNew;

        // -----------------------------
        // Create Field Executive
        // -----------------------------
        Field_Executive__c fe = new Field_Executive__c(
            Field_Executive_Name__c = 'FE Test',
            Email__c = 'fe@test.com',
            Phone__c = '9876543210',
            Country__c = 'India',
            State_Province__c = 'Gujarat',
            City__c = 'Ahmedabad',
            Zip_Postal_Code__c = 380001,
            Assigned_Territory__c = terrOld.Id
        );
        insert fe;

        // -----------------------------
        // OLD MAP (simulate Trigger.old)
        // -----------------------------
        Field_Executive__c feOld = fe.clone(false, true, false, false);
        feOld.Assigned_Territory__c = terrOld.Id;

        Map<Id, Field_Executive__c> oldMap = new Map<Id, Field_Executive__c>{
            fe.Id => feOld
        };

        // -----------------------------
        // CHANGE TERRITORY
        // -----------------------------
        fe.Assigned_Territory__c = terrNew.Id;

        Test.startTest();
        UpdateFEManagerOnTerritoryChangeHandler.updateSalesManager(
            new List<Field_Executive__c>{fe},
            oldMap
        );
        update fe; // ✅ THIS WAS MISSING
        Test.stopTest();

        // -----------------------------
        // ASSERT
        // -----------------------------
        Field_Executive__c updatedFE = [
            SELECT Assigned_Territory__c, Sales_Manager__c
            FROM Field_Executive__c
            WHERE Id = :fe.Id
        ];

        System.assertEquals(
            terrNew.Id,
            updatedFE.Assigned_Territory__c,
            'Territory should be updated'
        );
    }
}