public with sharing class AttendanceCardController {

    @AuraEnabled(cacheable=true)
    public static List<Attendance__c> getAttendanceData() {

        Date startOfWeek = Date.today().toStartOfWeek(); // Monday
        Date endOfWeek = startOfWeek.addDays(6);         // Sunday

        return [
            SELECT Id,
                   Check_in_Time__c,
                   Check_out_Time__c
            FROM Attendance__c
            WHERE Check_in_Time__c >= :startOfWeek
              AND Check_in_Time__c <= :endOfWeek
            ORDER BY Check_in_Time__c DESC
        ];
    }
}
