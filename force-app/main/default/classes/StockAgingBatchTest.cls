/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-12-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@IsTest
public class StockAgingBatchTest {

    @IsTest
    static void testAllAgingBuckets() {

        Date today = Date.today();

        List<Stock_Ledger__c> records = new List<Stock_Ledger__c>{
            new Stock_Ledger__c(Product_In__c = 10),               // 0–3
            new Stock_Ledger__c(Product_Out__c = 5),               // 3–6
            new Stock_Ledger__c(Product_In__c = 8, Product_Out__c = 4), // 6–9
            new Stock_Ledger__c(Product_In__c = 6),                // 9–12
            new Stock_Ledger__c(Product_Out__c = 7),               // 12–24
            new Stock_Ledger__c(Product_In__c = 12)                // >24
        };

        insert records;

        Test.setCreatedDate(records[0].Id, today.addMonths(-2));
        Test.setCreatedDate(records[1].Id, today.addMonths(-5));
        Test.setCreatedDate(records[2].Id, today.addMonths(-8));
        Test.setCreatedDate(records[3].Id, today.addMonths(-11));
        Test.setCreatedDate(records[4].Id, today.addMonths(-16));
        Test.setCreatedDate(records[5].Id, today.addMonths(-30));

        Test.startTest();
            Database.executeBatch(new StockAgingBatch(), 2);
        Test.stopTest();

        System.assertEquals(
            6,
            [SELECT COUNT() FROM Stock_Ledger__c]
        );
    }
}