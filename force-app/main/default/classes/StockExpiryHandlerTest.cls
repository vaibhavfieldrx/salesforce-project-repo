/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-12-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@IsTest
public class StockExpiryHandlerTest {

    /* ---------- Common Test Data ---------- */
    private static Warehouse__c createWarehouse() {
        Warehouse__c wh = new Warehouse__c(
            Name = 'Test Warehouse',
            Country__c = 'India',
            State_Province__c = 'Gujarat',
            City__c = 'Ahmedabad',
            Zip_Postal_Code__c = '380001'
        );
        insert wh;
        return wh;
    }

    private static Product2 createProduct() {
        Product2 p = new Product2(Name = 'Test Product', IsActive = true);
        insert p;
        return p;
    }

    /* ---------- TEST: handleStockLedger ---------- */
    @IsTest
    static void testHandleStockLedger_WithExpiredStock() {

        Warehouse__c wh = createWarehouse();
        Product2 prod = createProduct();

        Stock__c stock = new Stock__c(
            Product__c = prod.Id,
            Warehouse__c = wh.Id,
            Expiry_Date__c = Date.today(),
            Available_Quantity__c = 10
        );
        insert stock;

        Stock_Ledger__c ledger = new Stock_Ledger__c(
            Stock__c = stock.Id,
            Product__c = prod.Id,
            Warehouse__c = wh.Id,
            Expiry_Date__c = Date.today()
        );
        insert ledger;

        Test.startTest();
        StockExpiryHandler.handleStockLedger(new List<Stock_Ledger__c>{ ledger });
        Test.stopTest();

        List<Return_Order__c> orders = [
            SELECT Quantity__c, Reason__c
            FROM Return_Order__c
        ];

        System.assertEquals(1, orders.size());
        System.assertEquals('Expired', orders[0].Reason__c);
        System.assertEquals(1, orders[0].Quantity__c);
    }

    /* ---------- TEST: sendExpiryEmail ---------- */
    @IsTest
    static void testSendExpiryEmail_WithExpiredStock() {

        Warehouse__c wh = createWarehouse();
        Product2 prod = createProduct();

        insert new Stock__c(
            Product__c = prod.Id,
            Warehouse__c = wh.Id,
            Expiry_Date__c = Date.today(),
            Available_Quantity__c = 5
        );

        Test.startTest();
        StockExpiryHandler.sendExpiryEmail();
        Test.stopTest();

        System.assert(
            Limits.getEmailInvocations() > 0,
            'Email should be sent when stock expires today'
        );
    }
}