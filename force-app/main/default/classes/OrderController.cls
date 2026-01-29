/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-29-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class OrderController {

    @AuraEnabled
    public static Id createOrderWithItems(String orderJson) {
        try {
            System.debug('Incoming JSON => ' + orderJson);

            Map<String, Object> orderData =
                (Map<String, Object>) JSON.deserializeUntyped(orderJson);

            // ================= PRICEBOOK =================
            Id standardPricebookId = [
                SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1
            ].Id;

            // ================= ORDER =================
            Order ord = new Order();
            ord.AccountId = (Id) orderData.get('accountId');
            ord.BillToContactId = (Id) orderData.get('billToContactId');
            ord.Status = 'Draft';
            ord.EffectiveDate = Date.today();
            ord.Payment_Status__c = (String) orderData.get('paymentStatus');
            ord.Pricebook2Id = standardPricebookId;

            // -------- Customer Email & Phone --------
            Account acc = [
                SELECT Email__c, Phone
                FROM Account
                WHERE Id = :ord.AccountId
                LIMIT 1
            ];

              Contract contract = [
                SELECT Id
                FROM Contract
                WHERE AccountId = :ord.AccountId
                LIMIT 1
            ];
            ord.ContractId = contract.Id;
            ord.Customer_Email__c = acc.Email__c;
            ord.Customer_Mobile__c = acc.Phone;

            // ---------- Billing ----------
            Map<String, Object> billing =
                (Map<String, Object>) orderData.get('billingAddress');

            ord.BillingStreet     = (String) billing.get('street');
            ord.BillingCity       = (String) billing.get('city');
            ord.BillingState      = (String) billing.get('state');
            ord.BillingPostalCode = (String) billing.get('postalCode');
            ord.BillingCountry    = normalizeCountry(
                (String) billing.get('country')
            );

            // ---------- Shipping ----------
            Map<String, Object> shipping =
                (Map<String, Object>) orderData.get('shippingAddress');

            ord.ShippingStreet     = (String) shipping.get('street');
            ord.ShippingCity       = (String) shipping.get('city');
            ord.ShippingState      = (String) shipping.get('state');
            ord.ShippingPostalCode = (String) shipping.get('postalCode');
            ord.ShippingCountry    = normalizeCountry(
                (String) shipping.get('country')
            );

            ord.Warehouse__c = (Id) orderData.get('warehouseId');

            insert ord;

            // ================= ORDER ITEMS =================
            List<Object> products =
                (List<Object>) orderData.get('products');

            // 1️⃣ Collect productIds
            Set<Id> productIds = new Set<Id>();
            for (Object obj : products) {
                Map<String, Object> p = (Map<String, Object>) obj;
                productIds.add((Id) p.get('productId'));
            }

            // 2️⃣ Query PricebookEntries ONCE
            Map<Id, PricebookEntry> pbeMap = new Map<Id, PricebookEntry>();
            for (PricebookEntry pbe : [
                SELECT Id, Product2Id, UnitPrice
                FROM PricebookEntry
                WHERE Product2Id IN :productIds
                AND Pricebook2Id = :standardPricebookId
                AND IsActive = true
            ]) {
                pbeMap.put(pbe.Product2Id, pbe);
            }

            // 3️⃣ Create OrderItems
            List<OrderItem> items = new List<OrderItem>();

            for (Object obj : products) {
                Map<String, Object> p = (Map<String, Object>) obj;
                Id productId = (Id) p.get('productId');

                if (!pbeMap.containsKey(productId)) {
                    throw new AuraHandledException(
                        'Product not in Standard Pricebook: ' + productId
                    );
                }

                OrderItem oi = new OrderItem();
                oi.OrderId = ord.Id;
                oi.PricebookEntryId = pbeMap.get(productId).Id;
                oi.Quantity = (Decimal) p.get('quantity');
                oi.UnitPrice = (Decimal) p.get('unitPrice');
                oi.ServiceDate = Date.today();

                items.add(oi);
            }

            insert items;
            return ord.Id;

        } catch (Exception e) {
            System.debug('❌ ERROR => ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ================= COUNTRY NORMALIZER =================
    private static String normalizeCountry(String country) {
        if (country == null) return null;
        if (country == 'IN') return 'India'; // picklist-safe
        return country;
    }


      @AuraEnabled(cacheable=true)
    public static Map<String, Object> getOrderHistory(
        Id accountId,
        Integer pageSize,
        Integer pageNumber
    ) {
        Map<String, Object> result = new Map<String, Object>();

        if (accountId == null) {
            result.put('orders', new List<Order>());
            result.put('totalRecords', 0);
            return result;
        }

        Integer offsetSize = (pageNumber - 1) * pageSize;

        List<Order> orders = [
            SELECT Id, OrderNumber, Status, TotalAmount, CreatedDate
            FROM Order
            WHERE AccountId = :accountId
            ORDER BY CreatedDate DESC
            LIMIT :pageSize OFFSET :offsetSize
        ];

        Integer totalRecords = [
            SELECT COUNT()
            FROM Order
            WHERE AccountId = :accountId
        ];

        result.put('orders', orders);
        result.put('totalRecords', totalRecords);

        return result;
    }
}
