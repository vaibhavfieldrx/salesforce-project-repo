public class FieldExecutiveEmailHandler {
     // Sends welcome email when new Field Executives are inserted
 public static void sendWelcomeEmail(List<Field_Executive__c> fieldExecutives) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        for (Field_Executive__c fe : fieldExecutives) {
            // Check if Email field is not null before sending
            if (fe.Email__c != null) {
                 // Create a new email message
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] { fe.Email__c });// Add recipient email address
                mail.setSubject('Welcome to the team'); // Set email subject
                  // Build email body
                String body = 'Dear ' + fe.Field_Executive_Name__c + ', '; 
                body += 'Welcome aboard as a Field Executive for FieldRx. Your account has been created. ';
                body += 'You can log in to the app with your registered email. If you have any queries, please feel free to contact us. ';

                mail.setHtmlBody(body); // Set email body as HTML
                mails.add(mail);// Add this email to the list
            }
        }

        //  Null/empty check before sending email
        if (!mails.isEmpty()) {
            Messaging.sendEmail(mails);
        }
    }
}