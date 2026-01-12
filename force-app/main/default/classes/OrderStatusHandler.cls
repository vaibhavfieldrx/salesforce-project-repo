public class OrderStatusHandler {
    public static void setStatusBasedOnOtp(List<Order> orders) {
        for (Order ord : orders) {
            // Only proceed if OTP is entered
            if (String.isNotBlank(ord.OTP__c)) {
                //  Check if entered OTP matches generated OTP
                if (ord.OTP__c == ord.Generated_OTP__c) {
                    // If match, mark Delivered
                    if (ord.Status != 'Delivered') {
                        ord.Status = 'Delivered';
                        System.debug(' Correct OTP. Status set to Delivered for Order: ' + ord.Id);
                    }
                } else {
                    //  Wrong OTP entered — throw validation error
                    ord.addError('The OTP you entered is incorrect. Please try again.');
                    System.debug(' Wrong OTP entered for Order: ' + ord.Id);
                }
            }
        }
    }
}