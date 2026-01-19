public with sharing class FieldRx_ProductController {

    public class ProductWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String code;
        @AuraEnabled public String category;   // Category from Product Family
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public Decimal price;
    }

    @AuraEnabled(cacheable=true)
    public static List<ProductWrapper> getAllProducts() {

        if (!Schema.sObjectType.PricebookEntry.isAccessible() ||
            !Schema.sObjectType.Product2.isAccessible()) {
            throw new AuraHandledException('Access denied');
        }

        List<ProductWrapper> results = new List<ProductWrapper>();

        List<PricebookEntry> entries = [
    SELECT Product2.Id,
           Product2.Name,
           Product2.ProductCode,
           Product2.Family,
           Product2.IsActive,
           UnitPrice
    FROM PricebookEntry
    WHERE Pricebook2.IsStandard = true
    AND Product2.IsActive = true
    AND Product2.Family != NULL
];

        for(PricebookEntry pbe : entries){
    System.debug('CATEGORY FROM APEX = ' + pbe.Product2.Family);

    ProductWrapper pw = new ProductWrapper();
    pw.id = pbe.Product2.Id;
    pw.name = pbe.Product2.Name;
    pw.code = pbe.Product2.ProductCode;
    pw.category = pbe.Product2.Family;
    pw.isActive = pbe.Product2.IsActive;
    pw.price = pbe.UnitPrice;
    results.add(pw);
}

        return results;
    }
}