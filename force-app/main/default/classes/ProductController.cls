/**
 * @description       : ProductController for fetching products and their prices
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @last modified on  : 01-21-2026
**/
public with sharing class ProductController {

    // ------------------ GET ALL PRODUCTS ------------------
    @AuraEnabled(cacheable=true)
    public static List<FullProductWrapper> getAllProducts() {

        if (!Schema.sObjectType.Product2.isAccessible() ||
            !Schema.sObjectType.PricebookEntry.isAccessible()) {
            return new List<FullProductWrapper>();
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

        List<FullProductWrapper> products = new List<FullProductWrapper>();

        for (Product2 p : [
            SELECT Id, Name, ProductCode, Family, IsActive, Description
            FROM Product2
            WHERE IsActive = true
        ]) {
            FullProductWrapper w = new FullProductWrapper();
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

    // Wrapper for full product info
    public class FullProductWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String productCode;
        @AuraEnabled public String family;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public String description;
        @AuraEnabled public Decimal price;

        // No-arg constructor required for LWC
        public FullProductWrapper() {}
    }

    // ------------------ GET PRODUCTS BY IDS ------------------
    @AuraEnabled(cacheable=true)
    public static List<ProductPriceWrapper> getProducts(List<Id> productIds) {
        List<PricebookEntry> entries = [
            SELECT Product2Id, UnitPrice
            FROM PricebookEntry
            WHERE Product2Id IN :productIds
            AND IsActive = true
            AND Pricebook2.IsActive = true
            AND Pricebook2.Name = 'Standard Price Book'
        ];
        
        Map<Id, Decimal> productPriceMap = new Map<Id, Decimal>();
        for (PricebookEntry e : entries) {
            productPriceMap.put(e.Product2Id, e.UnitPrice);
        }

        List<ProductPriceWrapper> result = new List<ProductPriceWrapper>();
        for (Id pid : productIds) {
            result.add(new ProductPriceWrapper(pid, productPriceMap.get(pid)));
        }

        return result;
    }

    // Wrapper for only id + price
    public class ProductPriceWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public Decimal price;

        // No-arg constructor required for LWC
        public ProductPriceWrapper() {}

        // Constructor to initialize
        public ProductPriceWrapper(Id id, Decimal price) {
            this.id = id;
            this.price = price != null ? price : 0;
        }
    }

}
