global class StockAgingScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new StockAgingBatch(), 100);
    }
}