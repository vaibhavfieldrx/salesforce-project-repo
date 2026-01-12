public class InvoicestageonOrderHandler {

    public static void processOrder(List<Order> newList, Map<Id, Order> oldMap) {

        List<Invoice__c> toInsert = new List<Invoice__c>();
        List<Invoice__c> toUpdate = new List<Invoice__c>();
        for (Order o : newList) {

            if (o.Status == 'Delivered' &&
                oldMap.get(o.Id).Status != 'Delivered') {

                Invoice__c inv = new Invoice__c();
                inv.Order__c = o.Id;
                inv.Customer__c = o.AccountId;
                inv.Total_Amount__c = o.TotalAmount;
                inv.Invoice_Date__c = Date.today();
                inv.Stage__c = 'Created';
                inv.Payment_Status__c = 'Pending';

                toInsert.add(inv);
            }
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
        for (Order o : newList) {

            if (o.Payment_Status__c == 'Paid' &&
                oldMap.get(o.Id).Payment_Status__c != 'Paid') {

                List<Invoice__c> invList = [
                    SELECT Id, Stage__c, Payment_Status__c
                    FROM Invoice__c
                    WHERE Order__c = :o.Id
                    LIMIT 1
                ];

                if (!invList.isEmpty()) {
                    Invoice__c inv = invList[0];
                    inv.Stage__c = 'Paid';
                    inv.Payment_Status__c = 'Paid';
                    toUpdate.add(inv);
                }
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}