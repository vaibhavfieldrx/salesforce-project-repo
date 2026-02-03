public with sharing class OrderStatusChartController {

    @AuraEnabled(cacheable=true)
    public static List<StatusData> getOrderStatusData() {
        List<StatusData> result = new List<StatusData>();

        for (AggregateResult ar : [
            SELECT Status__c status, COUNT(Id) total
            FROM Order__c
            GROUP BY Status__c
        ]) {
            result.add(new StatusData(
                (String) ar.get('status'),
                (Integer) ar.get('total')
            ));
        }
        return result;
    }

    public class StatusData {
        @AuraEnabled public String label;
        @AuraEnabled public Integer value;

        public StatusData(String label, Integer value) {
            this.label = label;
            this.value = value;
        }
    }
}
