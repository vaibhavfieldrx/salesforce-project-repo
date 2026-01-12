global class FEPerformanceBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id FROM User WHERE IsActive = true'
        );
    }

    global void execute(Database.BatchableContext bc, List<User> users) {

        List<FE_Performance__c> performanceList = new List<FE_Performance__c>();
        Date today = Date.today();

        for (User u : users) {

            Integer orderCount = [
                SELECT COUNT()
                FROM Order
                WHERE OwnerId = :u.Id
                AND CreatedDate = TODAY
            ];

            Integer score = 0;
            if (orderCount > 20) score = 5;
            else if (orderCount >= 11) score = 3;
            else if (orderCount >= 6) score = 2;
            else if (orderCount >= 1) score = 1;

            FE_Performance__c perf = new FE_Performance__c(
                FE_Name__c= u.Id,
                Date__c = today,
                Order_Number__c = orderCount,
                Score__c = score );

            performanceList.add(perf);
        }

        insert performanceList;
    }

    global void finish(Database.BatchableContext bc) {
        // Optional: send email or log
    }
}