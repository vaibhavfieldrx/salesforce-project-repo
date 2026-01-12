/**
 * @description       : Attendance Controller with Admin/User based visibility
 * @author            :
 * @last modified on  : 01-08-2026
**/
public with sharing class AttendanceWiseController {

    /* ================= WRAPPER ================= */
    public class AttendanceDay {
        @AuraEnabled public Date attendanceDate;
        @AuraEnabled public Boolean isPresent;
        @AuraEnabled public String checkInTime;
        @AuraEnabled public String checkOutTime;
    }

    /* ================= MAIN METHOD ================= */
    @AuraEnabled(cacheable=true)
    public static List<AttendanceDay> getMyAttendance(
        Date startDate,
        Date endDate,
        Id selectedUserId
    ) {

        Id currentUserId = UserInfo.getUserId();

        // 🔑 Admin check (SAFE)
        User u = [
            SELECT Profile.Name
            FROM User
            WHERE Id = :currentUserId
            LIMIT 1
        ];

        Boolean isAdmin = (u.Profile.Name == 'System Administrator');

        // Decide user
        Id targetUserId = (isAdmin)
            ? selectedUserId
            : currentUserId;

        // Fetch attendance
        List<Attendance__c> attendanceRecords = [
            SELECT Check_In_Time__c, Check_Out_Time__c
            FROM Attendance__c
            WHERE User__c = :targetUserId
            AND Check_In_Time__c >= :startDate
            AND Check_In_Time__c <= :endDate
            ORDER BY Check_In_Time__c ASC
        ];

        // Date wise map
        Map<Date, Attendance__c> dateMap = new Map<Date, Attendance__c>();

        for (Attendance__c att : attendanceRecords) {
            Date d = att.Check_In_Time__c.date();
            if (!dateMap.containsKey(d)) {
                dateMap.put(d, att);
            } else {
                Attendance__c existing = dateMap.get(d);
                if (att.Check_In_Time__c < existing.Check_In_Time__c) {
                    existing.Check_In_Time__c = att.Check_In_Time__c;
                }
                if (att.Check_Out_Time__c != null &&
                    (existing.Check_Out_Time__c == null ||
                     att.Check_Out_Time__c > existing.Check_Out_Time__c)) {
                    existing.Check_Out_Time__c = att.Check_Out_Time__c;
                }
            }
        }

        // Build response
        List<AttendanceDay> result = new List<AttendanceDay>();

        for (Date d = startDate; d <= endDate; d = d.addDays(1)) {
            AttendanceDay day = new AttendanceDay();
            day.attendanceDate = d;

            if (dateMap.containsKey(d)) {
                Attendance__c att = dateMap.get(d);
                day.isPresent = true;
                day.checkInTime = att.Check_In_Time__c.format('HH:mm');
                day.checkOutTime = att.Check_Out_Time__c != null
                    ? att.Check_Out_Time__c.format('HH:mm')
                    : '--:--';
            } else {
                day.isPresent = false;
                day.checkInTime = '--:--';
                day.checkOutTime = '--:--';
            }
            result.add(day);
        }

        return result;
    }

    /* ================= USER DROPDOWN (ADMIN ONLY) ================= */
    @AuraEnabled(cacheable=true)
    public static List<User> getAllUsers() {

        Id currentUserId = UserInfo.getUserId();

        User u = [
            SELECT Profile.Name
            FROM User
            WHERE Id = :currentUserId
            LIMIT 1
        ];

        if (u.Profile.Name != 'System Administrator') {
            return new List<User>();
        }

        return [
            SELECT Id, Name
            FROM User
            WHERE IsActive = true
            ORDER BY Name
        ];
    }
}