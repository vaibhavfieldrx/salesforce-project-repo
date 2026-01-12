public with sharing class ProductController {

   @AuraEnabled(cacheable=true)
    public static List<ProductWrapper> getAllProducts() {

        if (!Schema.sObjectType.Product2.isAccessible() ||
            !Schema.sObjectType.PricebookEntry.isAccessible()) {
            return new List<ProductWrapper>();
        }

        Map<Id, Decimal> priceMap = new Map<Id, Decimal>();

        for (PricebookEntry pbe : [
            SELECT Product2Id, UnitPrice
            FROM PricebookEntry
            WHERE Pricebook2.IsStandard = true
            AND IsActive = true
        ]) {
            priceMap.put(pbe.Product2Id, pbe.UnitPrice);
        }

        List<ProductWrapper> products = new List<ProductWrapper>();

        for (Product2 p : [
            SELECT Id, Name, ProductCode, Family, IsActive, Description
            FROM Product2
            WHERE IsActive = true
        ]) {
            ProductWrapper w = new ProductWrapper();
            w.id = p.Id;
            w.name = p.Name;
            w.productCode = p.ProductCode;
            w.family = p.Family;
            w.isActive = p.IsActive;
            w.description = p.Description;
            w.price = priceMap.get(p.Id);
            products.add(w);
        }

        return products;
    }

    public class ProductWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String productCode;
        @AuraEnabled public String family;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public String description;
        @AuraEnabled public Decimal price;
    }
}