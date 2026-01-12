global class ActiveCustomerScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        UpdateActiveCustomersPerTerritory.executeLogic();
    }
}