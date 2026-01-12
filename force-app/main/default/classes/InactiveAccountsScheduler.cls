public class InactiveAccountsScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        InactiveAccounts batch = new InactiveAccounts();
        Database.executeBatch(batch, 100);
    }
}