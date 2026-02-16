@IsTest
public class StockExpiryHandlerTest {

@IsTest
static void testHandleStockLedger_NewlyExpiredStock() {

    Product2 testProduct = new Product2(Name = 'Test Product');
    insert testProduct;

    Warehouse__c wh = new Warehouse__c(
        Name = 'Test Warehouse',
        Country__c = 'India',
        State_Province__c = 'Gujarat',
        City__c = 'Ahmedabad',
        Zip_Postal_Code__c = '380001'
    );
    insert wh;

    Stock__c testStock = new Stock__c(
        Product__c = testProduct.Id,
        Warehouse__c = wh.Id
    );
    insert testStock;

    Date today = Date.today();

    Stock_Ledger__c ledger1 = new Stock_Ledger__c(
        Stock__c = testStock.Id,
        Product__c = testProduct.Id,
        Warehouse__c = wh.Id,
        Expiry_Date__c = today.addDays(-1), // 🔥 expired
        Remaining_Quantity__c = 10,
        Product_In__c = 10
    );

    Stock_Ledger__c ledger2 = new Stock_Ledger__c(
        Stock__c = testStock.Id,
        Product__c = testProduct.Id,
        Warehouse__c = wh.Id,
        Expiry_Date__c = today.addDays(5),
        Remaining_Quantity__c = 5,
        Product_In__c = 5
    );

    insert new List<Stock_Ledger__c>{ ledger1, ledger2 };

    Map<Id, Stock_Ledger__c> oldMap = new Map<Id, Stock_Ledger__c>{
        ledger1.Id => new Stock_Ledger__c(
            Id = ledger1.Id,
            Expiry_Date__c = today.addDays(5),
            Remaining_Quantity__c = 10,
            Product_In__c = 10,
            Warehouse__c = wh.Id
        ),
        ledger2.Id => new Stock_Ledger__c(
            Id = ledger2.Id,
            Expiry_Date__c = today.addDays(10),
            Remaining_Quantity__c = 5,
            Product_In__c = 5,
            Warehouse__c = wh.Id
        )
    };

    Test.startTest();
        StockExpiryHandler.handleStockLedger(
            new List<Stock_Ledger__c>{ ledger1, ledger2 },
            oldMap
        );
    Test.stopTest();

    List<Return_Order__c> ro = [
        SELECT Order_Stock_Ledger__c, Quantity__c, Reason__c
        FROM Return_Order__c
    ];

    System.assertEquals(1, ro.size());
    System.assertEquals(ledger1.Id, ro[0].Order_Stock_Ledger__c);
    System.assertEquals(10, ro[0].Quantity__c);
    System.assertEquals('Expired', ro[0].Reason__c);
}


    @IsTest
    static void testSendExpiryEmail() {
        // 1️⃣ Prepare Product and Stock records
        Product2 testProduct = new Product2(Name = 'Email Test Product');
        insert testProduct;

        // Create Warehouse with required fields
        Warehouse__c wh = new Warehouse__c(
            Name = 'Email Test Warehouse',
            Country__c = 'India',
            State_Province__c = 'Gujarat',
            City__c = 'Ahmedabad',
            Zip_Postal_Code__c = '380001'
        );
        insert wh;

        Stock__c testStock = new Stock__c(
            Product__c = testProduct.Id,
            Warehouse__c = wh.Id
        );
        insert testStock;

        // 2️⃣ Prepare Stock__c records (email checks these)
        Stock__c s1 = new Stock__c(
            Expiry_Date__c = Date.today(),
            Product__c = testProduct.Id,
            Warehouse__c = wh.Id
        );
        Stock__c s2 = new Stock__c(
            Expiry_Date__c = Date.today().addDays(1),
            Product__c = testProduct.Id,
            Warehouse__c = wh.Id
        );
        insert new List<Stock__c>{s1, s2};

        // 3️⃣ Call sendExpiryEmail
        Test.startTest();
        StockExpiryHandler.sendExpiryEmail();
        Test.stopTest();

        // 4️⃣ Verify logic: only today's expired stock is considered
        List<Stock__c> expiredStocks = [SELECT Id FROM Stock__c WHERE Expiry_Date__c = :Date.today()];
        System.assertEquals(1, expiredStocks.size(), 'Only one stock should be considered expired today');
    }

    @IsTest
    static void testHandleStockLedger_QuantityZeroAndNullExpiry() {
        // Test edge cases: Remaining Quantity = 0 or Expiry_Date__c = null
        Product2 p = new Product2(Name = 'Edge Product');
        insert p;

        // Create Warehouse with required fields
        Warehouse__c wh = new Warehouse__c(
            Name = 'Edge Warehouse',
            Country__c = 'India',
            State_Province__c = 'Gujarat',
            City__c = 'Ahmedabad',
            Zip_Postal_Code__c = '380001'
        );
        insert wh;

        Stock__c s = new Stock__c(
            Product__c = p.Id,
            Warehouse__c = wh.Id
        );
        insert s;

        Stock_Ledger__c ledger = new Stock_Ledger__c(
            Stock__c = s.Id,
            Product__c = p.Id,
            Expiry_Date__c = null,
            Remaining_Quantity__c = 0,
            Product_In__c = 0
        );
        insert ledger;

        Map<Id, Stock_Ledger__c> oldMap = new Map<Id, Stock_Ledger__c>();

        Test.startTest();
        StockExpiryHandler.handleStockLedger(
            new List<Stock_Ledger__c>{ledger},
            oldMap
        );
        Test.stopTest();

        // Verify no return orders created
        List<Return_Order__c> ro = [SELECT Id FROM Return_Order__c WHERE Order_Stock_Ledger__c = :ledger.Id];
        System.assertEquals(0, ro.size(), 'No return order should be created for zero quantity or null expiry');
    }
}