public class OTPService {

    public static void sendEmailOTP(Set<Id> orderIds) {

        List<Order> orders = [
            SELECT Id, Field_Executive__c
            FROM Order
            WHERE Id IN :orderIds
        ];

        for (Order o : orders) {

            if (o.Field_Executive__c == null) continue;

            // Generate OTP safely
            String otp = generateOTP();

            // Send OTP email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(o.Field_Executive__c);
            mail.setSaveAsActivity(false);
            mail.setSubject('Your OTP Code');
            mail.setPlainTextBody('Your OTP is: ' + otp);

            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        }
    }

   
    private static String generateOTP() {

        
        Integer raw = Math.abs(Crypto.getRandomInteger());

        // Force into 6-digit range manually
        // (1) Convert to string
        String s = String.valueOf(raw);

        // (2) Take last 6 digits always (safe & valid)
        if (s.length() > 6) {
            s = s.substring(s.length() - 6);
        }

     
        while (s.length() < 6) {
            s = '0' + s;
        }

        return s; 
    }
}