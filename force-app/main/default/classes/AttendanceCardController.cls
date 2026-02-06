public with sharing class AttendanceCardController {

    @AuraEnabled(cacheable=true)
    public static List<Attendance__c> getAttendanceData() {

        Id currentUserId = UserInfo.getUserId();

        Date monday = Date.today().toStartOfWeek();

        DateTime startOfWeek = DateTime.newInstance(
            monday.year(),
            monday.month(),
            monday.day()
        );

        DateTime endOfWeek = startOfWeek.addDays(7).addSeconds(-1);

        // Get all records of this user for this week
        List<Attendance__c> records = [
            SELECT Id,
                   Check_in_Time__c,
                   Check_out_Time__c,
                   OwnerId
            FROM Attendance__c
            WHERE Check_in_Time__c >= :startOfWeek
              AND Check_in_Time__c <= :endOfWeek
            //   AND OwnerId = :currentUserId   // ✅ Logged-in FE
            ORDER BY Check_in_Time__c DESC
        ];

        // Map to keep only ONE record per day
        Map<Date, Attendance__c> dayWiseMap = new Map<Date, Attendance__c>();

        for (Attendance__c att : records) {

            Date day = att.Check_in_Time__c.date();

            // Since sorted DESC, first one is latest
            if (!dayWiseMap.containsKey(day)) {
                dayWiseMap.put(day, att);
            }
        }

        return dayWiseMap.values();
    }
}