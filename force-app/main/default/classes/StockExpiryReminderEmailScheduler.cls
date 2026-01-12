global class StockExpiryReminderEmailScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
       StockExpiryReminderEmailHandler.sendExpiryReminders();
    }
}