@IsTest
public class StockLedgerTriggerTest {

    @IsTest
    static void testTriggerAfterUpdate_WhenStockBecomesExpired() {

        // Product
        Product2 p = new Product2(Name = 'Test Product');
        insert p;

        // Warehouse
        Warehouse__c wh = new Warehouse__c(
            Name = 'Test Warehouse',
            Country__c = 'India',
            State_Province__c = 'Gujarat',
            City__c = 'Ahmedabad',
            Zip_Postal_Code__c = '380001'
        );
        insert wh;

        // Stock
        Stock__c s = new Stock__c(
            Product__c = p.Id,
            Warehouse__c = wh.Id
        );
        insert s;

        // STEP 1️⃣ Insert NON-EXPIRED Stock Ledger
        Stock_Ledger__c ledger = new Stock_Ledger__c(
            Stock__c = s.Id,
            Product__c = p.Id,
            Warehouse__c = wh.Id,
            Expiry_Date__c = Date.today().addDays(5), // NOT expired
            Remaining_Quantity__c = 10,
            Product_In__c = 10
        );
        insert ledger;

        // STEP 2️⃣ Update → MAKE IT EXPIRED
        ledger.Expiry_Date__c = Date.today().addDays(-1);

        Test.startTest();
        update ledger; // 🔥 Trigger fires here
        Test.stopTest();

        // STEP 3️⃣ Assert Return Order
        List<Return_Order__c> ro = [
            SELECT Order_Stock_Ledger__c, Quantity__c, Reason__c
            FROM Return_Order__c
            WHERE Order_Stock_Ledger__c = :ledger.Id
        ];

        System.assertEquals(1, ro.size(), 'Return Order must be created');
        System.assertEquals(10, ro[0].Quantity__c);
        System.assertEquals('Expired', ro[0].Reason__c);
    }
}
