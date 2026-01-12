public class ReturnOrderHandler {

    public static void handleReturnPayments(List<Return_Order__c> newList) {

        
        Set<Id> returnIdsToProcess = new Set<Id>();
        List<Return_Order__c> validReturns = new List<Return_Order__c>();

        for (Return_Order__c ret : newList) {
            if ((ret.Return_Status__c == 'Approved' || ret.Return_Status__c == 'Completed')
                && ret.Payment_Created__c == false) {
                validReturns.add(ret);
                returnIdsToProcess.add(ret.Id);
            }
        }

        if (validReturns.isEmpty()) {
            System.debug('No valid return orders for payment processing.');
            return;
        }

      
        Map<Id, Payment__c> existingPayments = new Map<Id, Payment__c>();
        for (Payment__c pay : [
            SELECT Id, Order_Return__c
            FROM Payment__c
            WHERE Order_Return__c IN :returnIdsToProcess
        ]) {
            existingPayments.put(pay.Order_Return__c, pay);
        }

        
        List<Payment__c> newPayments = new List<Payment__c>();
        List<Return_Order__c> returnsToUpdate = new List<Return_Order__c>();

        for (Return_Order__c ret : validReturns) {

           
            if (existingPayments.containsKey(ret.Id)) {
                continue;
            }

            
            Payment__c payment = new Payment__c(
                Account__c = ret.Customer__c,
                Order__c = ret.Order__c,
                Order_Return__c = ret.Id,
                Amount__c = ret.Refund_Amount__c,
                Payment_Date__c = System.now(),
                Payment_Method__c = 'Refund',
                Payment_Type__c = 'Refund',
                Status__c = 'Completed',
                Notes__c = 'Auto-created refund for Return Order: ' + ret.Name,
                Processed_By__c = UserInfo.getUserId()
            );

            newPayments.add(payment);

            // Update Return record flag
            Return_Order__c retUpdate = new Return_Order__c(
                Id = ret.Id,
                Payment_Created__c = true
            );
            returnsToUpdate.add(retUpdate);
        }

       
        if (!newPayments.isEmpty()) {
            insert newPayments;
        }

        if (!returnsToUpdate.isEmpty()) {
            update returnsToUpdate;
        }

        System.debug('Payments created: ' + newPayments.size());
        System.debug('Return orders updated: ' + returnsToUpdate.size());
    }
}