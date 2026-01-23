/**
 * @description       : ProductController for fetching products and their prices
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @last modified on  : 01-23-2026
**/
public with sharing class ProductController {

    // ================== GET ALL PRODUCTS WITH PAGINATION ==================
    @AuraEnabled(cacheable=true)
   public static Map<String, Object> getAllProducts(
    Integer pageSize,
    Integer pageNumber
) {
    Integer offsetSize = (pageNumber - 1) * pageSize;

    Integer totalRecords = [
        SELECT COUNT()
        FROM Product2
        WHERE IsActive = true
    ];

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
        SELECT Id, Name, ProductCode, Family, Description
        FROM Product2
        WHERE IsActive = true
        ORDER BY Name
        LIMIT :pageSize OFFSET :offsetSize
    ]) {
        FullProductWrapper w = new FullProductWrapper();
        w.id = p.Id;
        w.name = p.Name;
        w.productCode = p.ProductCode;
        w.family = p.Family;
        w.description = p.Description;
        w.price = priceMap.get(p.Id);
        products.add(w);
    }

    return new Map<String, Object>{
        'products' => products,
        'totalRecords' => totalRecords
    };
}

    // ================== RESPONSE WRAPPER ==================
    public class ProductPageResult {
        @AuraEnabled public List<FullProductWrapper> products;
        @AuraEnabled public Integer totalRecords;

        public ProductPageResult(List<FullProductWrapper> products, Integer totalRecords) {
            this.products = products;
            this.totalRecords = totalRecords;
        }
    }

    // ================== FULL PRODUCT WRAPPER ==================
    public class FullProductWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String productCode;
        @AuraEnabled public String family;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public String description;
        @AuraEnabled public Decimal price;

        public FullProductWrapper() {}
    }

    // ================== GET PRODUCTS BY IDS ==================
    @AuraEnabled(cacheable=true)
    public static List<ProductPriceWrapper> getProducts(List<Id> productIds) {

        if (productIds == null || productIds.isEmpty()) {
            return new List<ProductPriceWrapper>();
        }

        List<PricebookEntry> entries = [
            SELECT Product2Id, UnitPrice
            FROM PricebookEntry
            WHERE Product2Id IN :productIds
            AND IsActive = true
            AND Pricebook2.IsStandard = true
        ];

        Map<Id, Decimal> productPriceMap = new Map<Id, Decimal>();
        for (PricebookEntry e : entries) {
            productPriceMap.put(e.Product2Id, e.UnitPrice);
        }

        List<ProductPriceWrapper> result = new List<ProductPriceWrapper>();
        for (Id pid : productIds) {
            result.add(new ProductPriceWrapper(
                pid,
                productPriceMap.containsKey(pid) ? productPriceMap.get(pid) : 0
            ));
        }

        return result;
    }

    // ================== ID + PRICE WRAPPER ==================
    public class ProductPriceWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public Decimal price;

        public ProductPriceWrapper() {}

        public ProductPriceWrapper(Id id, Decimal price) {
            this.id = id;
            this.price = price;
        }
    }
}
