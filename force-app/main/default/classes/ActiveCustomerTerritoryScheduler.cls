global class ActiveCustomerTerritoryScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        UpdateActiveCustomersPerTerritory.executeLogic();
    }
}