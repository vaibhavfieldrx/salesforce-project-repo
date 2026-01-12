public class AccountValidationHandler {

    
    private static String normalizePhone(String phone) {
        if (phone == null) return null;
        String onlyDigits = phone.replaceAll('[^0-9]', '');
        if (onlyDigits.length() > 10) {
            onlyDigits = onlyDigits.substring(onlyDigits.length() - 10);
        }
        return onlyDigits;
    }

    
    public static void validateEmailAndPhone(List<Account> newList, Map<Id, Account> oldMap) {

        Set<String> emailSet = new Set<String>();
        Set<String> phoneSet = new Set<String>();

      
        for (Account acc : newList) {
            Account oldAcc = (oldMap != null && oldMap.containsKey(acc.Id)) ? oldMap.get(acc.Id) : null;

            if (acc.Email__c != null && (oldAcc == null || acc.Email__c != oldAcc.Email__c)) {
                emailSet.add(acc.Email__c.toLowerCase());
            }
            if (acc.Phone != null && (oldAcc == null || acc.Phone != oldAcc.Phone)) {
                phoneSet.add(normalizePhone(acc.Phone));
            }
        }

        if (emailSet.isEmpty() && phoneSet.isEmpty()) {
            return;
        }

      
        Map<String, Id> emailToAccId = new Map<String, Id>();
        Map<String, Id> phoneToAccId = new Map<String, Id>();

        List<Account> existingAccounts = [
            SELECT Id, Email__c, Phone
            FROM Account
            WHERE (Email__c IN :emailSet AND Email__c != null)
               OR (Phone != null)
        ];

        for (Account existing : existingAccounts) {
            if (existing.Email__c != null) {
                emailToAccId.put(existing.Email__c.toLowerCase(), existing.Id);
            }
            if (existing.Phone != null) {
                phoneToAccId.put(normalizePhone(existing.Phone), existing.Id);
            }
        }

       
        for (Account acc : newList) {
            String newEmail = acc.Email__c != null ? acc.Email__c.toLowerCase() : null;
            String newPhone = normalizePhone(acc.Phone);

            if (newEmail != null && emailToAccId.containsKey(newEmail) && emailToAccId.get(newEmail) != acc.Id) {
                acc.Email__c.addError('Email already exists for another customer.');
            }

            if (newPhone != null && phoneToAccId.containsKey(newPhone) && phoneToAccId.get(newPhone) != acc.Id) {
                acc.Phone.addError('Phone number already exists for another customer.');
            }
        }
    }
}