public class OrderDiscountCalcHandler {

    public static void calculateDiscountedAmount(List<Order> orderList) {

        for (Order ord : orderList) {

            // Case 1: If TotalAmount is null → set Discounted_Amount__c = 0
            if (ord.TotalAmount == null) {
                ord.Discounted_Amount__c = 0;
                continue; // Skip further processing for this record
            }

            // Case 2: Handle invalid discount values
            if (ord.Discount__c != null && (ord.Discount__c < 0 || ord.Discount__c > 100)) {
                ord.Discount__c.addError('Discount must be between 0 and 100.');
                continue;
            }

            // Case 3: Apply discount calculation
            if (ord.Discount__c != null && ord.Discount__c > 0) {
                Decimal discountedValue = ord.TotalAmount * (1 - (ord.Discount__c / 100));
                ord.Discounted_Amount__c = discountedValue;
            } else {
                ord.Discounted_Amount__c = ord.TotalAmount;
            }
        }
    }
}