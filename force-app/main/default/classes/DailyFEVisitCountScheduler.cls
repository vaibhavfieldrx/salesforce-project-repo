global class DailyFEVisitCountScheduler
    implements Schedulable {

    global void execute(SchedulableContext sc) {
        Database.executeBatch(
            new DailyFEVisitCountBatch(),
            200
        );
    }
}