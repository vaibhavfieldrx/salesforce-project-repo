public with sharing class CreateInvoiceOnOrder {
 
    public static void createInvoices(List<Order> orders) {
 
        // Collect Delivered orders
        Set<Id> deliveredOrderIds = new Set<Id>();
        for (Order o : orders) {
            if (o.Status == 'Delivered') {
                deliveredOrderIds.add(o.Id);
            }
        }
        if (deliveredOrderIds.isEmpty()) return;
 
        // Check existing invoices to avoid duplicates
        Map<Id, Invoice__c> existing = new Map<Id, Invoice__c>();
        for (Invoice__c inv : [
            SELECT Id, Order__c 
            FROM Invoice__c 
            WHERE Order__c IN :deliveredOrderIds
        ]) {
            existing.put(inv.Order__c, inv);
        }
 
        List<Invoice__c> toInsert = new List<Invoice__c>();
 
        for (Order ord : orders) {
 
            // Only when Delivered
            if (ord.Status != 'Delivered') continue;
 
            // Skip if already has invoice
            if (existing.containsKey(ord.Id)) continue;
 
            // Create invoice
            Invoice__c inv = new Invoice__c();
            inv.Order__c = ord.Id;  // Custom lookup
 
            if (ord.AccountId != null) {
                inv.Customer__c = ord.AccountId;  // Custom lookup
            }
 
            inv.Invoice_Date__c = Date.today();  // Custom date field
            inv.Payment_Status__c = 'Draft';            // Custom picklist
 
            toInsert.add(inv);
        }
 
        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
    }
}