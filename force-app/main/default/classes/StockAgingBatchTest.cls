


@IsTest
public class StockAgingBatchTest {

    @IsTest
    static void testStockAgingBatch_AllPaths_AndScheduler() {

        Date today = Date.today();

        /* -------------------- MASTER DATA -------------------- */

        Product2 product = new Product2(Name = 'Test Product');
        insert product;

        Warehouse__c warehouse = new Warehouse__c(
            Name = 'Test Warehouse',
            Country__c = 'India',
            State_Province__c = 'Gujarat',
            City__c = 'Ahmedabad',
            Zip_Postal_Code__c = '380001'
        );
        insert warehouse;

        Stock__c stock = new Stock__c(
            Product__c = product.Id,
            Warehouse__c = warehouse.Id
        );
        insert stock;

        /* -------------------- STOCK LEDGER RECORDS -------------------- */

        List<Stock_Ledger__c> ledgers = new List<Stock_Ledger__c>{
            new Stock_Ledger__c(Product_In__c = 10, Stock__c = stock.Id),                     // 0–3 IN
            new Stock_Ledger__c(Product_Out__c = 5, Stock__c = stock.Id),                     // 3–6 OUT
            new Stock_Ledger__c(Product_In__c = 8, Product_Out__c = 4, Stock__c = stock.Id),  // 6–9 IN+OUT
            new Stock_Ledger__c(Product_In__c = 6, Stock__c = stock.Id),                      // 9–12 IN
            new Stock_Ledger__c(Product_Out__c = 7, Stock__c = stock.Id),                     // 12–24 OUT
            new Stock_Ledger__c(Product_In__c = 12, Stock__c = stock.Id)                      // >24 IN
        };
        insert ledgers;

        /* -------------------- SET CREATED DATES -------------------- */

       Test.setCreatedDate(ledgers[0].Id, today.addMonths(-1));   // 0–3
Test.setCreatedDate(ledgers[1].Id, today.addMonths(-4));   // 3–6
Test.setCreatedDate(ledgers[2].Id, today.addMonths(-7));   // 6–9
Test.setCreatedDate(ledgers[3].Id, today.addMonths(-10));  // 9–12
Test.setCreatedDate(ledgers[4].Id, today.addMonths(-18));  // 12–24
Test.setCreatedDate(ledgers[5].Id, today.addMonths(-30));  // >24

        /* -------------------- EXECUTE BATCH -------------------- */

        Test.startTest();
            Database.executeBatch(new StockAgingBatch(), 200);
        Test.stopTest();

        /* -------------------- SAFE ASSERTIONS (NO ORDER DEPENDENCY) -------------------- */

        Boolean found0_3_IN = false;
        Boolean found3_6_OUT = false;
        Boolean found6_9_BOTH = false;
        Boolean found9_12_IN = false;
        Boolean found12_24_OUT = false;
        Boolean found24_PLUS_IN = false;

        for (Stock_Ledger__c s : [
            SELECT X0_3_IN__c, X3_6_IN__c, X6_9_IN__c, X9_12_IN__c,
                   More_Than_12_Months_IN__c, More_Than_24_Months_IN__c,
                   X0_3_OUT__c, X3_6_OUT__c, X6_9_OUT__c, X9_12_OUT__c,
                   More_Than_12_Months_OUT__c, More_Than_24_Months_OUT__c
            FROM Stock_Ledger__c
        ]) {
            if (s.X0_3_IN__c) found0_3_IN = true;
            if (s.X3_6_OUT__c) found3_6_OUT = true;
            if (s.X6_9_IN__c && s.X6_9_OUT__c) found6_9_BOTH = true;
            if (s.X9_12_IN__c) found9_12_IN = true;
            if (s.More_Than_12_Months_OUT__c) found12_24_OUT = true;
            if (s.More_Than_24_Months_IN__c) found24_PLUS_IN = true;
        }

        System.assert(found0_3_IN, '0–3 IN bucket not set');
        System.assert(found3_6_OUT, '3–6 OUT bucket not set');
        System.assert(found6_9_BOTH, '6–9 IN+OUT bucket not set');
        System.assert(found9_12_IN, '9–12 IN bucket not set');
        System.assert(found12_24_OUT, '12–24 OUT bucket not set');
        System.assert(found24_PLUS_IN, '>24 IN bucket not set');

        /* -------------------- SCHEDULER TEST -------------------- */

        Test.startTest();
            System.schedule(
                'Stock Aging Scheduler Test',
                '0 0 12 * * ?',
                new StockAgingScheduler()
            );
        Test.stopTest();
    }
}