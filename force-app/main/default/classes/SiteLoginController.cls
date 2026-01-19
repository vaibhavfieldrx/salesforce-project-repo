global with sharing class SiteLoginController {
    @AuraEnabled
    public static void login(String username, String password) {
        try {
            Site.login(username, password, '/s/order');
        } catch (Exception e) {
            throw new AuraHandledException('Invalid username or password.');
        }
    }
}