@IsTest
public class OrderDiscountCalcHandlerTest {

    private static Order createOrderWithAmount(Decimal unitPrice, Decimal discount) {

        Territory__c terr = new Territory__c(
            City__c = 'Ahmedabad',
            State__c = 'Gujarat',
            Region__c = 'West',
            Status_Is_Active__c = true
        );
        insert terr;

        Account acc = new Account(
            Name = 'Test Account',
            Territory__c = terr.Id
        );
        insert acc;

        Id stdPricebookId = Test.getStandardPricebookId();

        Order ord = new Order(
            Name = 'Test Order',
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Territory__c = terr.Id,
            Pricebook2Id = stdPricebookId,
            Discount__c = discount,
            Customer_Email__c = 'test@gmail.com'
        );
        insert ord;

        Product2 prod = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPricebookId,
            Product2Id = prod.Id,
            UnitPrice = unitPrice,
            IsActive = true
        );
        insert pbe;

        OrderItem oi = new OrderItem(
            OrderId = ord.Id,
            Quantity = 1,
            UnitPrice = unitPrice,
            PricebookEntryId = pbe.Id
        );
        insert oi;

        return [
            SELECT Id, TotalAmount, Discount__c
            FROM Order WHERE Id = :ord.Id
        ];
    }

    // ✅ Valid Discount
    @IsTest
    static void testValidDiscount() {
        Order ord = createOrderWithAmount(1000, 10);

        Test.startTest();
        OrderDiscountCalcHandler.calculateDiscountedAmount(new List<Order>{ord});
        update ord;
        Test.stopTest();
    }

    // ✅ Zero Discount
    @IsTest
    static void testZeroDiscount() {
        Order ord = createOrderWithAmount(500, 0);

        Test.startTest();
        OrderDiscountCalcHandler.calculateDiscountedAmount(new List<Order>{ord});
        update ord;
        Test.stopTest();
    }

    // ✅ Null Discount
    @IsTest
    static void testNullDiscount() {
        Order ord = createOrderWithAmount(750, null);

        Test.startTest();
        OrderDiscountCalcHandler.calculateDiscountedAmount(new List<Order>{ord});
        update ord;
        Test.stopTest();
    }



    // ✅ TotalAmount = NULL
    @IsTest
    static void testTotalAmountNull() {

        Territory__c terr = new Territory__c(
            City__c = 'Ahmedabad',
            State__c = 'Gujarat',
            Region__c = 'West',
            Status_Is_Active__c = true
        );
        insert terr;

        Account acc = new Account(
            Name = 'Null Amount Account',
            Territory__c = terr.Id
        );
        insert acc;

        Id stdPricebookId = Test.getStandardPricebookId();

        Order ord = new Order(
            Name = 'Null Order',
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Territory__c = terr.Id,
            Pricebook2Id = stdPricebookId,
            Customer_Email__c = 'test@gmail.com'
        );
        insert ord;

        Test.startTest();
        OrderDiscountCalcHandler.calculateDiscountedAmount(new List<Order>{ord});
        update ord;
        Test.stopTest();
    }

    @IsTest
static void testBeforeUpdate_InvalidDiscount() {

    // Territory
    Territory__c terr = new Territory__c(
        City__c = 'Ahmedabad',
        State__c = 'Gujarat',
        Region__c = 'West',
        Status_Is_Active__c = true
    );
    insert terr;

    // Account
    Account acc = new Account(
        Name = 'Update Invalid Discount Account',
        Territory__c = terr.Id
    );
    insert acc;

    // Pricebook
    Id pbId = Test.getStandardPricebookId();

    // Order (VALID INSERT FIRST)
    Order ord = new Order(
        Name = 'Update Discount Order',
        AccountId = acc.Id,
        Status = 'Draft',
        EffectiveDate = Date.today(),
        Territory__c = terr.Id,
        Pricebook2Id = pbId,
        Discount__c = 10,
        Customer_Email__c = 'test@gmail.com'
    );
    insert ord;

    // Product
    Product2 prod = new Product2(Name = 'P1', IsActive = true);
    insert prod;

    // Pricebook Entry
    PricebookEntry pbe = new PricebookEntry(
        Pricebook2Id = pbId,
        Product2Id = prod.Id,
        UnitPrice = 1000,
        IsActive = true
    );
    insert pbe;

    // OrderItem → creates TotalAmount
    OrderItem oi = new OrderItem(
        OrderId = ord.Id,
        Quantity = 1,
        UnitPrice = 1000,
        PricebookEntryId = pbe.Id
    );
    insert oi;

    // 🔥 BEFORE UPDATE INVALID DISCOUNT
    ord.Discount__c = 150;

    Test.startTest();
    try {
        update ord;
        System.assert(false, 'Update should fail due to invalid discount');
    } catch (DmlException ex) {
        System.assert(
            ex.getMessage().contains('Discount must be between 0 and 100'),
            'Expected validation error'
        );
    }
    Test.stopTest();
}

}
