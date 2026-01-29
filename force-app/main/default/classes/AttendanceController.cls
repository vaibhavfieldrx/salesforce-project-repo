/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-29-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class AttendanceController {

    @AuraEnabled(cacheable=true)
    public static List<AttendanceWrapper> getFEAttendance(Date selectedDate) {

        Date filterDate = selectedDate != null ? selectedDate : Date.today();

        // 1️⃣ Get all active users
        List<User> users = [
            SELECT Id, Name, UserRole.Name, Department
            FROM User
            WHERE IsActive = true
        ];

        // 2️⃣ Get attendance for selected date
        Map<Id, Attendance__c> attendanceByUser = new Map<Id, Attendance__c>();

        for (Attendance__c att : [
            SELECT Id,
                   User__c,
                   Check_in_Time__c,
                   Check_out_Time__c,
                   Status__c
            FROM Attendance__c
            WHERE Check_in_Time__c != NULL
            AND DAY_ONLY(Check_in_Time__c) = :filterDate
        ]) {
            attendanceByUser.put(att.User__c, att);
        }

        // 3️⃣ Merge logic
        List<AttendanceWrapper> result = new List<AttendanceWrapper>();

        for (User u : users) {
            AttendanceWrapper w = new AttendanceWrapper();
            w.userId = u.Id;
            w.userName = u.Name;
            w.role = u.UserRole != null ? u.UserRole.Name : null;
            w.department = u.Department;

            if (attendanceByUser.containsKey(u.Id)) {
                Attendance__c att = attendanceByUser.get(u.Id);
                w.checkIn = att.Check_in_Time__c;
                w.checkOut = att.Check_out_Time__c;
                w.status = att.Status__c;
            } else {
                // 🔥 ABSENT LOGIC
                w.status = 'Absent';
            }

            result.add(w);
        }

        return result;
    }

    // ---------- Wrapper ----------
    public class AttendanceWrapper {
        @AuraEnabled public Id userId;
        @AuraEnabled public String userName;
        @AuraEnabled public String role;
        @AuraEnabled public String department;
        @AuraEnabled public Datetime checkIn;
        @AuraEnabled public Datetime checkOut;
        @AuraEnabled public String status;
    }
}
