public class StockExpiryHandler {

    // ✅ Make sure method name and signature match exactly with trigger call
    public static void handleStockLedger(List<Stock_Ledger__c> stockList) {
        List<Return_Order__c> returnOrders = new List<Return_Order__c>();
        Date today = Date.today();

        for (Stock_Ledger__c stock : stockList) {
            if (stock.Expiry_Date__c == today) {
                Return_Order__c ro = new Return_Order__c();
                ro.Order_Stock_Ledger__c = stock.Id;
                ro.Stock__c = stock.Stock__c;
                ro.Product__c = stock.Product__c;
                ro.Return_Date__c = System.now();
                ro.Return_Status__c = 'Pending';
                ro.Reason__c = 'Expired';
                returnOrders.add(ro);
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