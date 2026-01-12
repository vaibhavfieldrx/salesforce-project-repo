public with sharing class AttendanceController {

    @AuraEnabled(cacheable=true)
    public static List<Attendance__c> getFEAttendance() {

        return [
            SELECT Id,
                   Name,
                   Check_in_Time__c,
                   Check_out_Time__c,
                   Status__c
            FROM Attendance__c
            ORDER BY CreatedDate DESC
        ];
    }
}