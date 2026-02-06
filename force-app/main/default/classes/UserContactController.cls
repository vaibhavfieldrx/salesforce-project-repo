/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-06-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class UserContactController {

    @AuraEnabled(cacheable=true)
    public static String getUserDepartment() {

        User u = [
            SELECT ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        if (u.ContactId == null) {
            return 'NO_CONTACT';
        }

        Contact c = [
            SELECT Department
            FROM Contact
            WHERE Id = :u.ContactId
            LIMIT 1
        ];

        return String.isBlank(c.Department) ? 'UNKNOWN' : c.Department;
    }
}
