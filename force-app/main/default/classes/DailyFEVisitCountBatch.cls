global class DailyFEVisitCountBatch
    implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator([
            SELECT Id, Field_Executive__c
            FROM Attendance__c
            WHERE Visit_Date__c = TODAY
            AND Field_Executive__c != NULL
        ]);
    }

    global void execute(
        Database.BatchableContext bc,
        List<Attendance__c> scope
    ) {

        Map<Id, Integer> feVisitMap = new Map<Id, Integer>();

        for (Attendance__c att : scope) {
            Id feId = att.Field_Executive__c;

            if (!feVisitMap.containsKey(feId)) {
                feVisitMap.put(feId, 1);
            } else {
                feVisitMap.put(feId, feVisitMap.get(feId) + 1);
            }
        }

        List<Field_Executive__c> feToUpdate = new List<Field_Executive__c>();

        for (Id feId : feVisitMap.keySet()) {
            feToUpdate.add(new Field_Executive__c(
                Id = feId,
                Daily_Visit_Count__c = feVisitMap.get(feId)
            ));
        }

        if (!feToUpdate.isEmpty()) {
            update feToUpdate;
        }
    }

    global void finish(Database.BatchableContext bc) {
       
    }
}