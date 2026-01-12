public class LowStockScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new LowStockBatch(), 200);
    }
}