public class LowStockBatch implements Database.Batchable<SObject>, Database.Stateful {

    List<Stock__c> lowStockList = new List<Stock__c>();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Name, Product__c, Warehouse__c, Total_Quantity__c ' +
            'FROM Stock__c WHERE Total_Quantity__c < 20'
        );
    }

    public void execute(Database.BatchableContext bc, List<Stock__c> scope) {
        lowStockList.addAll(scope);
    }

    public void finish(Database.BatchableContext bc) {

        if (lowStockList.isEmpty()) {
            return;
        }

        String body = 'LOW STOCK ALERT\n\n' +
                      'The following stock records have Total Quantity less than 20:\n\n';

        for (Stock__c s : lowStockList) {
            body += 
                'Stock Record: ' + s.Name +
                '\nProduct: ' + s.Product__c +
                '\nWarehouse: ' + s.Warehouse__c +
                '\nTotal Quantity: ' + s.Total_Quantity__c +
                '\n-------------------------\n';
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] {'nitinr@codeplateau.com'});  
        mail.setSubject('Low Stock Alert – Total Quantity Warning');
        mail.setPlainTextBody(body);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
    }
}