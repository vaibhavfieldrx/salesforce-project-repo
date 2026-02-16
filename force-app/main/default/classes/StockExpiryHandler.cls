public class StockExpiryHandler {

    // ✅ Make sure method name and signature match exactly with trigger call
 public static void handleStockLedger(
        List<Stock_Ledger__c> newList,
        Map<Id, Stock_Ledger__c> oldMap
    ) {
        List<Return_Order__c> returnOrders = new List<Return_Order__c>();
        Date today = Date.today();

        for (Stock_Ledger__c stock : newList) {

            Stock_Ledger__c oldStock = oldMap != null ? oldMap.get(stock.Id) : null;

            Boolean newlyExpired =
                stock.Expiry_Date__c != null &&
                stock.Expiry_Date__c <= today &&
                (oldStock == null || oldStock.Expiry_Date__c > today);

            if (newlyExpired && stock.Remaining_Quantity__c > 0) {

                returnOrders.add(new Return_Order__c(
                    Order_Stock_Ledger__c = stock.Id,
                    Stock__c = stock.Stock__c,
                    Product__c = stock.Product__c,
                    Quantity__c = stock.Remaining_Quantity__c,
                    Return_Date__c = System.now(),
                    Return_Status__c = 'Pending',
                    Reason__c = 'Expired'
                ));
            }
        }

        if (!returnOrders.isEmpty()) {
            insert returnOrders;
        }
    }


     // ✅ Daily mail to admin
    public static void sendExpiryEmail() {
        List<Stock__c> expiredStocks = [
            SELECT Name, Expiry_Date__c
            FROM Stock__c
            WHERE Expiry_Date__c = :Date.today()
        ];

        if (!expiredStocks.isEmpty()) {
            String body = 'The following stock items have expired today:\n\n';
            for (Stock__c s : expiredStocks) {
                body += '- ' + s.Name + ' (Expiry: ' + s.Expiry_Date__c + ')\n';
            }

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { 'ashwiniv@codeplateau.com' }); 
            email.setSubject('Daily Stock Expiry Alert');
            email.setPlainTextBody(body);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        }
    }
   
}