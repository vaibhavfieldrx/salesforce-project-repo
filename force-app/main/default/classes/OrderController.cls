public with sharing class OrderController {

    @AuraEnabled
    public static Id createOrderWithItems(Map<String, Object> orderData) {

        // =====================
        // 1️⃣ CREATE ORDER
        // =====================
        Id standardPricebookId = [
            SELECT Id
            FROM Pricebook2
            WHERE IsStandard = true
            LIMIT 1
        ].Id;

        Order o = new Order();
        o.AccountId = (Id) orderData.get('accountId');
        o.BillToContactId = (Id) orderData.get('billToContactId');
        o.EffectiveDate = Date.today();
        o.Status = 'Activated';
        o.Payment_Status__c = (String) orderData.get('paymentStatus');
        // o.TotalAmount = (Decimal) orderData.get('totalAmount');
        o.Pricebook2Id = standardPricebookId;
        o.Name = 'Order - ' + Date.today();

        // Billing Address
        Map<String, Object> billing =
            (Map<String, Object>) orderData.get('billingAddress');

        o.BillingStreet     = (String) billing.get('street');
        o.BillingCity       = (String) billing.get('city');
        o.BillingState      = (String) billing.get('state');
        o.BillingPostalCode = (String) billing.get('postalCode');
        o.BillingCountry    = (String) billing.get('country');

        // Shipping Address
        Map<String, Object> shipping =
            (Map<String, Object>) orderData.get('shippingAddress');

        o.ShippingStreet     = (String) shipping.get('street');
        o.ShippingCity       = (String) shipping.get('city');
        o.ShippingState      = (String) shipping.get('state');
        o.ShippingPostalCode = (String) shipping.get('postalCode');
        o.ShippingCountry    = (String) shipping.get('country');

        // Warehouse Lookup
        o.Warehouse__c = (Id) orderData.get('warehouseId');

        insert o; // 🔥 OrderId is generated here

        // =====================
        // 2️⃣ CREATE ORDER ITEMS
        // =====================
        List<OrderItem> items = new List<OrderItem>();

        List<Object> products =
            (List<Object>) orderData.get('products');

        for (Object obj : products) {
            Map<String, Object> p =
                (Map<String, Object>) obj;

            OrderItem oi = new OrderItem();
            oi.OrderId = o.Id; // ✅ MOST IMPORTANT
            oi.Product2Id = (Id) p.get('productId');
            oi.Quantity = (Decimal) p.get('quantity');
            oi.UnitPrice = (Decimal) p.get('unitPrice');
            // oi.TotalPrice = (Decimal) p.get('lineTotal');
            oi.ServiceDate = Date.today();

            items.add(oi);
        }

        if (!items.isEmpty()) {
            insert items;
        }

        return o.Id;
    }
}
