global class FEPerformanceScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new FEPerformanceBatch(), 200);
    }
}