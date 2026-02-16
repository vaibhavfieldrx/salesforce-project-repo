public class OrderDiscountCalcHandler {

    public static void calculateDiscountedAmount(List<Order> orders) {

        // ✅ Coverable guard clause
        if (orders == null || orders.isEmpty()) {
            return;
        }

        for (Order ord : orders) {

            // ✅ TotalAmount null safety
            if (ord.TotalAmount == null) {
                ord.TotalAmount = 0;
            }

            // ✅ Null discount treated as 0
            Decimal discount = ord.Discount__c == null ? 0 : ord.Discount__c;

            // ✅ Validation: < 0 OR > 100
            if (discount < 0 || discount > 100) {
                ord.addError('Discount must be between 0 and 100');
                continue;
            }

            // ✅ Discount calculation
            Decimal discountedAmount =
                ord.TotalAmount - (ord.TotalAmount * discount / 100);

            ord.TotalAmount = discountedAmount;
        }
    }
}
