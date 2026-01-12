global class StockExpiryScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        StockExpiryHandler.sendExpiryEmail();
    }
}