/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-16-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global with sharing class SiteLoginControllerTest {

    @AuraEnabled
    public static void login(String username, String password) {
        User u = [
            SELECT Id, IsActive
            FROM User
            WHERE Username = :username
            LIMIT 1
        ];

        if (!u.IsActive) {
            throw new AuraHandledException('Invalid username or password.');
        }

        Site.login(username, password, '/');
    }
}