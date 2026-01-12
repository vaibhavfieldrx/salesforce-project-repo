global class DailySalesBatch
implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id FROM Opportunity WHERE StageName = \'Closed Won\' AND CloseDate =  TODAY'
        );
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        // No processing required
    }

    global void finish(Database.BatchableContext bc) {
        DailySalesPDFService.generatePDFAndSend();
    }
}