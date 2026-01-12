public class InvoiceHandler {
    public static void createInvoiceLines(List<Invoice__c> invoices) {
System.debug('createInvoiceLines');

        Set<Id> orderIds = new Set<Id>();

        for (Invoice__c inv : invoices) {
            if (inv.Order__c != null) {
                orderIds.add(inv.Order__c);
            }
        }
System.debug('orderIds :' + orderIds);
        if (orderIds.isEmpty()) return;

       
        Map<Id, List<OrderItem>> orderToItems = new Map<Id, List<OrderItem>>();
        for (OrderItem oi : [
            SELECT Id, OrderId, Product2Id, Product2.Name, Quantity, UnitPrice, TotalPrice
            FROM OrderItem
            WHERE OrderId IN :orderIds
        ]) {
            if (!orderToItems.containsKey(oi.OrderId)) {
                orderToItems.put(oi.OrderId, new List<OrderItem>());
            }
            orderToItems.get(oi.OrderId).add(oi);
        }

        
        List<Invoice_line_Item__c> newLines = new List<Invoice_line_Item__c>();

        for (Invoice__c inv : invoices) {
            if (inv.Order__c == null || !orderToItems.containsKey(inv.Order__c)) continue;

            for (OrderItem oi : orderToItems.get(inv.Order__c)) {

                Invoice_line_Item__c il = new Invoice_line_Item__c();

                il.Invoice__c     = inv.Id;
                il.Product__c = oi.Product2.Id;
                il.Quantity__c    = oi.Quantity;
                il.Unit_Price__c  = oi.UnitPrice;

                newLines.add(il);
            }
        }

       
        if (!newLines.isEmpty()) {
            insert newLines;
        }
    }
}