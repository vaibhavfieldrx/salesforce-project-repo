/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 02-10-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class AttendanceController {

    @AuraEnabled(cacheable=true)
    public static List<AttendanceWrapper> getFEAttendance(Date selectedDate) {

        // 🔥 Logged-in FE
        Id loggedInUserId = UserInfo.getUserId();

        // 🔥 Get logged-in user details
        User u = [
            SELECT Id, Name, UserRole.Name, Department
            FROM User
            WHERE Id = :loggedInUserId
        ];

        // 🔥 Get ALL attendance records of logged-in FE
        List<Attendance__c> attList = [
            SELECT Id,
                   User__c,
                   Check_in_Time__c,
                   Check_out_Time__c,
                   Status__c
            FROM Attendance__c
            // WHERE User__c = :loggedInUserId
            ORDER BY Check_in_Time__c DESC
        ];

        // 🔥 Prepare response list
        List<AttendanceWrapper> result = new List<AttendanceWrapper>();

        // If attendance records exist
        if (!attList.isEmpty()) {
            for (Attendance__c att : attList) {
                AttendanceWrapper w = new AttendanceWrapper();
                w.userId = u.Id;
                w.userName = u.Name;
                w.role = u.UserRole != null ? u.UserRole.Name : null;
                w.department = u.Department;
                w.checkIn = att.Check_in_Time__c;
                w.checkOut = att.Check_out_Time__c;
                w.status = att.Status__c;

                result.add(w);
            }
        } else {
            // ✅ No records → show Absent (single row)
            AttendanceWrapper w = new AttendanceWrapper();
            w.userId = u.Id;
            w.userName = u.Name;
            w.role = u.UserRole != null ? u.UserRole.Name : null;
            w.department = u.Department;
            w.status = 'Absent';

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
