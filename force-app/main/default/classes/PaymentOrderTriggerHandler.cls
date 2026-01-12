/*public class PaymentOrderTriggerHandler {

    public static void createPaymentRecords(List<Order> newList, Map<Id, Order> oldMap) {

        Set<Id> orderIdsToProcess = new Set<Id>();

        // Identify orders where Create_Payment__c changed from FALSE → TRUE
        for (Order ord : newList) {
            Order oldOrd = oldMap.get(ord.Id);
            if (ord.Create_Payment__c == true && (oldOrd == null || oldOrd.Create_Payment__c == false)) {
                orderIdsToProcess.add(ord.Id);
            }
        }

        if (orderIdsToProcess.isEmpty()) return;

        // Fetch existing payments linked to these orders
        Map<Id, Payment__c> existingPayments = new Map<Id, Payment__c>();
        for (Payment__c pay : [
            SELECT Id, Order__c FROM Payment__c WHERE Order__c IN :orderIdsToProcess
        ]) {
            existingPayments.put(pay.Order__c, pay);
        }

        // Fetch order details (to get TotalAmount)
        List<Payment__c> newPayments = new List<Payment__c>();
        for (Order ord : [
            SELECT Id, TotalAmount
            FROM Order
            WHERE Id IN :orderIdsToProcess
        ]) {
            if (!existingPayments.containsKey(ord.Id)) {
                Payment__c pay = new Payment__c();
                pay.Order__c = ord.Id;
                pay.Amount__c = ord.TotalAmount != null ? ord.TotalAmount : 0;
                newPayments.add(pay);
            } else {
                ord.addError('Payment record already exists for this order.');
            }
        }

        // Insert new Payment records
        if (!newPayments.isEmpty()) {
            insert newPayments;
            System.debug('Payment Records Created: ' + newPayments);
        }
    }
}

public class PaymentOrderTriggerHandler {

    public static void createPaymentRecords(List<Order> newList, Map<Id, Order> oldMap) {
        Set<Id> orderIdsToProcess = new Set<Id>();
        for (Order ord : newList) {
            Order oldOrd = oldMap != null ? oldMap.get(ord.Id) : null;
            if (ord.Create_Payment__c == true && (oldOrd == null || oldOrd.Create_Payment__c == false)) {
                orderIdsToProcess.add(ord.Id);
            }
        }
        if (orderIdsToProcess.isEmpty()) {
            System.debug('No Orders to process for payment creation.');
            return;
        }
        Map<Id, Payment__c> existingPayments = new Map<Id, Payment__c>();
        for (Payment__c pay : [
            SELECT Id, Order__c FROM Payment__c WHERE Order__c IN :orderIdsToProcess
        ]) {
            existingPayments.put(pay.Order__c, pay);
        }
        List<Payment__c> newPayments = new List<Payment__c>();
        for (Order ord : [
            SELECT Id, TotalAmount FROM Order WHERE Id IN :orderIdsToProcess
        ]) {
            if (!existingPayments.containsKey(ord.Id)) {
                Payment__c pay = new Payment__c();
                pay.Order__c = ord.Id;
                pay.Amount__c = (ord.TotalAmount != null) ? ord.TotalAmount : 0;
                newPayments.add(pay);
            } else {
                ord.addError('A Payment record already exists for this Order.');
            }
        }
        if (!newPayments.isEmpty()) {
            insert newPayments;
        } else {
            System.debug('No new Payment records to insert.');
        }
    }
}*/
public class PaymentOrderTriggerHandler {

    public static void createPaymentRecords(List<Order> newList, Map<Id, Order> oldMap) {
        Set<Id> orderIdsToProcess = new Set<Id>();

        for (Order ord : newList) {
            Order oldOrd = oldMap != null ? oldMap.get(ord.Id) : null;
            if (ord.Create_Payment__c == true && (oldOrd == null || oldOrd.Create_Payment__c == false)) {
                orderIdsToProcess.add(ord.Id);
            }
        }

        if (orderIdsToProcess.isEmpty()) {
            System.debug('No Orders to process for payment creation.');
            return;
        }

        Map<Id, Payment__c> existingPayments = new Map<Id, Payment__c>();
        for (Payment__c pay : [
            SELECT Id, Order__c FROM Payment__c WHERE Order__c IN :orderIdsToProcess
        ]) {
            existingPayments.put(pay.Order__c, pay);
        }

        Map<Id, Order> orderMap = new Map<Id, Order>(
            [SELECT Id, TotalAmount FROM Order WHERE Id IN :orderIdsToProcess]
        );

        List<Payment__c> paymentsToInsert = new List<Payment__c>();
        Map<Id, String> ordersWithErrors = new Map<Id, String>();

        for (Id orderId : orderIdsToProcess) {
            if (!existingPayments.containsKey(orderId)) {
                Order ord = orderMap.get(orderId);
                Payment__c pay = new Payment__c(
                    Order__c = orderId,
                    Amount__c = (ord.TotalAmount != null) ? ord.TotalAmount : 0
                );
                paymentsToInsert.add(pay);
            } else {
                ordersWithErrors.put(orderId, 'A Payment record already exists for this Order.');
            }
        }

        if (!paymentsToInsert.isEmpty()) {
            insert paymentsToInsert;
        } else {
            System.debug('No new Payment records to insert.');
        }

        if (!ordersWithErrors.isEmpty()) {
            for (Order ord : newList) {
                if (ordersWithErrors.containsKey(ord.Id)) {
                    ord.addError(ordersWithErrors.get(ord.Id));
                }
            }
        }
    }
}