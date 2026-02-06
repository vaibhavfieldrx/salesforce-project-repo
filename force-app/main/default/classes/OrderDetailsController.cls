public with sharing class OrderDetailsController {

    // Wrapper class to send Order + OrderItems to LWC
    public class OrderWrapper {
        @AuraEnabled public Order order;
        @AuraEnabled public List<OrderItem> orderItems;
    }

    @AuraEnabled(cacheable=true)
    public static OrderWrapper getOrderDetails(Id orderId) {
        OrderWrapper wrapper = new OrderWrapper();

        // Fetch the order
        wrapper.order = [SELECT Id, OrderNumber, Status, AccountId, EffectiveDate, TotalAmount
                         FROM Order
                         WHERE Id = :orderId
                         LIMIT 1];

        // Fetch the order items
        wrapper.orderItems = [SELECT Id, Product2.Name, Product2.StockKeepingUnit, Quantity, UnitPrice, TotalPrice
                              FROM OrderItem
                              WHERE OrderId = :orderId];

        return wrapper;
    }
}
