public with sharing class OrderTrendChartController {

    @AuraEnabled(cacheable=true)
    public static List<MonthlyData> getMonthlyOrderTrend() {

        // 1️⃣ Query existing data
        List<AggregateResult> data = [
            SELECT CALENDAR_MONTH(CreatedDate) month,
                   COUNT(Id) total
            FROM Order__c
            WHERE CreatedDate = LAST_N_MONTHS:12
            GROUP BY CALENDAR_MONTH(CreatedDate)
        ];

        // 2️⃣ Store DB result in map
        Map<Integer, Integer> monthToCount = new Map<Integer, Integer>();
        for (AggregateResult ar : data) {
            monthToCount.put(
                (Integer) ar.get('month'),
                (Integer) ar.get('total')
            );
        }

        // 3️⃣ Month name map
        Map<Integer, String> monthMap = new Map<Integer, String>{
            1=>'Jan', 2=>'Feb', 3=>'Mar', 4=>'Apr',
            5=>'May', 6=>'Jun', 7=>'Jul', 8=>'Aug',
            9=>'Sep', 10=>'Oct', 11=>'Nov', 12=>'Dec'
        };

        // 4️⃣ Build LAST 12 MONTHS (even if no data)
        List<MonthlyData> result = new List<MonthlyData>();
        Date today = Date.today();

        for (Integer i = 11; i >= 0; i--) {
            Date d = today.addMonths(-i);
            Integer monthNum = d.month();

            result.add(new MonthlyData(
                monthMap.get(monthNum),
                monthToCount.containsKey(monthNum)
                    ? monthToCount.get(monthNum)
                    : 0
            ));
        }

        return result;
    }

    public class MonthlyData {
        @AuraEnabled public String label;
        @AuraEnabled public Integer value;

        public MonthlyData(String label, Integer value) {
            this.label = label;
            this.value = value;
        }
    }
}
