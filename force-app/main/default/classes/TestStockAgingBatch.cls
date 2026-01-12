global class TestStockAgingBatch implements Database.Batchable<SObject> {
 
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, CreatedDate FROM Stock_Ledger__c LIMIT 5
        ]);
    }
 
    global void execute(Database.BatchableContext bc, List<Stock_Ledger__c> scope) {
        Date today = Date.today();
        for (Stock_Ledger__c s : scope) {
            Integer months = today.monthsBetween(s.CreatedDate.date());
            System.debug('Record ID: ' + s.Id + ' | Months old: ' + months);
        }
    }
 
    global void finish(Database.BatchableContext bc) {
        System.debug('Batch Completed ✅');
    }
}