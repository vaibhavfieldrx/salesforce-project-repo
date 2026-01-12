public with sharing class FieldRx_ProductController {

    @AuraEnabled(cacheable=true)
    public static List<ProductWrapper> getProducts() {

        if (!Schema.sObjectType.Product2.isAccessible()) {
            throw new AuraHandledException('User does not have access to Products');
        }
        if (!Schema.sObjectType.PricebookEntry.isAccessible()) {
            throw new AuraHandledException('User does not have access to Pricebook Entries');
        }

        List<Product2> products = [
            SELECT Id, Name, ProductCode, Family, IsActive,
            (SELECT UnitPrice FROM PricebookEntries 
             WHERE Pricebook2.IsStandard = true LIMIT 1)
            FROM Product2
            WHERE IsActive = true
        ];

        List<ProductWrapper> result = new List<ProductWrapper>();

        for (Product2 p : products) {
            ProductWrapper pw = new ProductWrapper();
            pw.id = p.Id;
            pw.name = p.Name;
            pw.code = p.ProductCode;
            pw.category = p.Family;
            pw.isActive = p.IsActive;
            pw.price = 0;

            if (!p.PricebookEntries.isEmpty()) {
                pw.price = p.PricebookEntries[0].UnitPrice;
            }

            result.add(pw);
        }

        return result;
    }

   
    public class ProductWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String code;
        @AuraEnabled public String category;
        @AuraEnabled public Decimal price;
        @AuraEnabled public Boolean isActive;
    }
}