/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-30-2026
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
            ord.Discount__c = (Decimal) orderData.get('discount');
            ord.Discounted_Amount__c = (Decimal) orderData.get('discountAmount');

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
                oi.Discount__c = (Integer) p.get('Discount');

                items.add(oi);
            }

            insert items;
            return ord.Id;

        } catch (Exception e) {
            System.debug('❌ ERROR => ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
@AuraEnabled
public static void updateOrderWithItems(String orderJson) {
    try {
        System.debug('Update JSON => ' + orderJson);

        Map<String, Object> orderData =
            (Map<String, Object>) JSON.deserializeUntyped(orderJson);

        /* ================= VALIDATION ================= */
        Id orderId = (Id) orderData.get('orderId');
        if (orderId == null) {
            throw new AuraHandledException('OrderId is required for update');
        }

        /* ================= FETCH ORDER ================= */
        Order ord = [
            SELECT Id, Pricebook2Id
            FROM Order
            WHERE Id = :orderId
            LIMIT 1
        ];

        /* ================= UPDATE BASIC FIELDS ================= */
        ord.Payment_Status__c = (String) orderData.get('paymentStatus');
        ord.Discount__c = orderData.containsKey('discount')
            ? (Decimal) orderData.get('discount')
            : 0;
        ord.Discounted_Amount__c = orderData.containsKey('discountAmount')
            ? (Decimal) orderData.get('discountAmount')
            : 0;
        ord.Warehouse__c = (Id) orderData.get('warehouseId');
        ord.BillToContactId = (Id) orderData.get('billToContactId');

        /* ================= BILLING ADDRESS ================= */
        Map<String, Object> billing =
            (Map<String, Object>) orderData.get('billingAddress');

        if (billing != null) {
            ord.BillingStreet     = (String) billing.get('street');
            ord.BillingCity       = (String) billing.get('city');
            ord.BillingState      = (String) billing.get('state');
            ord.BillingPostalCode = (String) billing.get('postalCode');
            ord.BillingCountry    = normalizeCountry(
                (String) billing.get('country')
            );
        }

        /* ================= SHIPPING ADDRESS ================= */
        Map<String, Object> shipping =
            (Map<String, Object>) orderData.get('shippingAddress');

        if (shipping != null) {
            ord.ShippingStreet     = (String) shipping.get('street');
            ord.ShippingCity       = (String) shipping.get('city');
            ord.ShippingState      = (String) shipping.get('state');
            ord.ShippingPostalCode = (String) shipping.get('postalCode');
            ord.ShippingCountry    = normalizeCountry(
                (String) shipping.get('country')
            );
        }

        update ord;

        /* ================= DELETE OLD ITEMS ================= */
        List<OrderItem> oldItems = [
            SELECT Id FROM OrderItem WHERE OrderId = :orderId
        ];
        if (!oldItems.isEmpty()) {
            delete oldItems;
        }

        /* ================= INSERT NEW ITEMS ================= */
        List<Object> products =
            (List<Object>) orderData.get('products');

        if (products == null || products.isEmpty()) {
            return;
        }

        /* 1️⃣ Collect ProductIds */
        Set<Id> productIds = new Set<Id>();
        for (Object obj : products) {
            Map<String, Object> p = (Map<String, Object>) obj;
            productIds.add((Id) p.get('productId'));
        }

        /* 2️⃣ Get PricebookEntries */
        Map<Id, PricebookEntry> pbeMap = new Map<Id, PricebookEntry>();
        for (PricebookEntry pbe : [
            SELECT Id, Product2Id
            FROM PricebookEntry
            WHERE Product2Id IN :productIds
              AND Pricebook2Id = :ord.Pricebook2Id
              AND IsActive = true
        ]) {
            pbeMap.put(pbe.Product2Id, pbe);
        }

        /* 3️⃣ Create OrderItems */
        List<OrderItem> newItems = new List<OrderItem>();
        for (Object obj : products) {
            Map<String, Object> p = (Map<String, Object>) obj;
            Id productId = (Id) p.get('productId');

            if (!pbeMap.containsKey(productId)) {
                throw new AuraHandledException(
                    'Product not in Pricebook: ' + productId
                );
            }

            OrderItem oi = new OrderItem();
            oi.OrderId = orderId;
            oi.PricebookEntryId = pbeMap.get(productId).Id;
            oi.Quantity = (Decimal) p.get('quantity');
            oi.UnitPrice = (Decimal) p.get('unitPrice');
            oi.Discount__c = p.containsKey('discount')
                ? (Decimal) p.get('discount')
                : 0;
            oi.ServiceDate = Date.today();

            newItems.add(oi);
        }

        insert newItems;

    } catch (Exception e) {
        System.debug('❌ UPDATE ERROR => ' + e.getMessage());
        throw new AuraHandledException('Update failed: ' + e.getMessage());
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


        // ================= EDIT ORDER =================
    @AuraEnabled(cacheable=true)
    public static OrderWrapper getOrderForEdit(Id orderId) {

        if (orderId == null) {
            throw new AuraHandledException('OrderId is required');
        }

        Order o = [
            SELECT Id,
                   AccountId,
                   Status,
                   TotalAmount,
                   Payment_Status__c,
                   Discounted_Amount__c,
                   Discount__c,
                   BillingStreet,
                   BillingCity,
                   BillingState,
                   BillingPostalCode,
                   BillingCountry,
                   ShippingStreet,
                   ShippingCity,
                   ShippingState,
                   ShippingPostalCode,
                   ShippingCountry,
                   Warehouse__c,
                   (
                       SELECT Product2Id,
                              Quantity,
                              UnitPrice,
                              Discount__c
                       FROM OrderItems
                   )
            FROM Order
            WHERE Id = :orderId
            LIMIT 1
        ];

        return new OrderWrapper(o);
    }

    // ================= WRAPPERS =================
    public class OrderWrapper {
        @AuraEnabled public Id orderId;
        @AuraEnabled public Id accountId;
        @AuraEnabled public String status;
        @AuraEnabled public Decimal totalAmount;
        @AuraEnabled public String paymentStatus;
        @AuraEnabled public Id warehouseId;
@AuraEnabled public Decimal Discount;
@AuraEnabled public Decimal DiscountAmount;
        @AuraEnabled public AddressWrapper billingAddress;
        @AuraEnabled public AddressWrapper shippingAddress;
        @AuraEnabled public List<OrderItemWrapper> products;

        public OrderWrapper(Order o) {
            orderId = o.Id;
            accountId = o.AccountId;
            status = o.Status;
            totalAmount = o.TotalAmount;
            paymentStatus = o.Payment_Status__c;
            warehouseId = o.Warehouse__c;
            Discount= o.Discount__c;
            DiscountAmount = o.Discounted_Amount__c;

            billingAddress = new AddressWrapper(
                o.BillingStreet,
                o.BillingCity,
                o.BillingState,
                o.BillingPostalCode,
                o.BillingCountry
            );

            shippingAddress = new AddressWrapper(
                o.ShippingStreet,
                o.ShippingCity,
                o.ShippingState,
                o.ShippingPostalCode,
                o.ShippingCountry
            );

            products = new List<OrderItemWrapper>();
            for (OrderItem oi : o.OrderItems) {
                products.add(new OrderItemWrapper(oi));
            }
        }
    }

    public class OrderItemWrapper {
        @AuraEnabled public Id productId;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal unitPrice;
        @AuraEnabled public Decimal discount;
        

        public OrderItemWrapper(OrderItem oi) {
            productId = oi.Product2Id;
            quantity = oi.Quantity;
            unitPrice = oi.UnitPrice;
            discount = oi.Discount__c;
        }
    }

    public class AddressWrapper {
        @AuraEnabled public String street;
        @AuraEnabled public String city;
        @AuraEnabled public String state;
        @AuraEnabled public String postalCode;
        @AuraEnabled public String country;

        public AddressWrapper(
            String street,
            String city,
            String state,
            String postalCode,
            String country
        ) {
            this.street = street;
            this.city = city;
            this.state = state;
            this.postalCode = postalCode;
            this.country = country;
        }
    }
}
