public class OrderInvoiceHandler {

    public static void createInvoices(List<Order> newOrders) {

        Set<Id> orderIds = new Set<Id>();
        for (Order ord : newOrders) {
            orderIds.add(ord.Id);
        }

        // Fetch Order Items
        Map<Id, List<OrderItem>> orderToItems = new Map<Id, List<OrderItem>>();
        for (OrderItem oi : [
            SELECT Id, OrderId, Product2.Name, Quantity, TotalPrice
            FROM OrderItem
            WHERE OrderId IN :orderIds
        ]) {
          if (!orderToItems.containsKey(oi.OrderId)) {
        orderToItems.put(oi.OrderId, new List<OrderItem>());
        }
          orderToItems.get(oi.OrderId).add(oi);

        }

        List<Invoice> invoicesToInsert = new List<Invoice>();

        // Create Invoice from Order
        for (Order ord : newOrders) {

            Invoice inv = new Invoice();

            inv.Order__c = ord.Id;
            inv.Customer__c = ord.AccountId;
           // inv.TotalAmount = ord.TotalAmount;

            invoicesToInsert.add(inv);
        }

        insert invoicesToInsert;

        // Invoice Lines
        List<InvoiceLine> lineItemsToInsert = new List<InvoiceLine>();

        for (Invoice inv : invoicesToInsert) {

            List<OrderItem> items = orderToItems.get(inv.Order__c);

            if (items != null) {
                for (OrderItem oi : items) {
                    InvoiceLine line = new InvoiceLine();

                   line.InvoiceId = inv.Id;
                    line.Product2Id = oi.Product2Id;
                    line.Quantity = oi.Quantity;
                    //line.LineAmount = oi.LineAmount;

                    lineItemsToInsert.add(line);
                }
            }
        }

        if (!lineItemsToInsert.isEmpty()) {
            insert lineItemsToInsert;
        }
    }
}