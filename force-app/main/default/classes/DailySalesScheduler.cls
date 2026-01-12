global class DailySalesScheduler
implements Schedulable {

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new DailySalesBatch());
    }
}