public class OrderTriggerHandlers {
    public static void handleDeliveredOrders(List<Order> newOrders, Map<Id, Order> oldOrdersMap) {

        if (newOrders == null || newOrders.isEmpty()) {
            return; 
        }

        List<Task> tasksToInsert = new List<Task>();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        try {
            
            Map<Id, Order> safeOldMap = (oldOrdersMap == null) ? new Map<Id, Order>() : oldOrdersMap;

            Set<Id> feIds = new Set<Id>();

            for (Order o : newOrders) {
                Order oldOrder = safeOldMap.containsKey(o.Id) ? safeOldMap.get(o.Id) : null;
                Boolean wasDelivered = (oldOrder != null && oldOrder.Status == 'Delivered');
                if (o.Status == 'Delivered' && !wasDelivered && o.Field_Executive__c != null) {
                    feIds.add(o.Field_Executive__c);
                }
            }

            //query if Field Executives exist
            Map<Id, Field_Executive__c> feMap = new Map<Id, Field_Executive__c>();
            if (!feIds.isEmpty()) {
                feMap = new Map<Id, Field_Executive__c>(
                    [SELECT Id, Email__c, Field_Executive_Name__c, User__c 
                     FROM Field_Executive__c 
                     WHERE Id IN :feIds]
                );
            }

           
            Set<Id> userIds = new Set<Id>();
            for (Field_Executive__c fe : feMap.values()) {
                if (fe.User__c != null) userIds.add(fe.User__c);
            }

            Map<Id, User> activeUsers = new Map<Id, User>();
            if (!userIds.isEmpty()) {
                for (User u : [SELECT Id, IsActive FROM User WHERE Id IN :userIds]) {
                    if (u.IsActive) activeUsers.put(u.Id, u);
                }
            }

            //Create Tasks and Emails safely
            for (Order o : newOrders) {
                Order oldOrder = safeOldMap.containsKey(o.Id) ? safeOldMap.get(o.Id) : null;
                Boolean wasDelivered = (oldOrder != null && oldOrder.Status == 'Delivered');

                if (o.Status == 'Delivered' && !wasDelivered) {
                    Id ownerToAssign = o.OwnerId;

                    // If FE User is valid and active, assign the task to them
                    if (o.Field_Executive__c != null && feMap.containsKey(o.Field_Executive__c)) {
                        Id feUser = feMap.get(o.Field_Executive__c).User__c;
                        if (feUser != null && activeUsers.containsKey(feUser)) {
                            ownerToAssign = feUser;
                        }
                    }

                    // Create task
                    Task t = new Task(
                        WhatId = o.Id,
                        OwnerId = ownerToAssign,
                        Subject = 'Follow up: Check Delivery Status',
                        Status = 'Not Started',
                        Priority = 'High',
                        ActivityDate = System.today().addDays(2)
                    );
                    tasksToInsert.add(t);

                    // Prepare email only if FE has valid email
                    if (o.Field_Executive__c != null && feMap.containsKey(o.Field_Executive__c)) {
                        Field_Executive__c fe = feMap.get(o.Field_Executive__c);
                        if (fe != null && String.isNotBlank(fe.Email__c)) {
                            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                            mail.setToAddresses(new String[]{ fe.Email__c });
                            mail.setSubject('Follow-up Required: Order Delivered');
                            mail.setPlainTextBody(
                                'Hello ' + fe.Field_Executive_Name__c + ',\n\n' +
                                'Order ' + o.OrderNumber + ' has been marked as Delivered.\n' +
                                'Please follow up with the customer to confirm delivery status.\n\n' +
                                'Thanks.'
                            );
                            emails.add(mail);
                        }
                    }
                }
            }

            // Insert Tasks 
            if (!tasksToInsert.isEmpty()) {
                Database.SaveResult[] results = Database.insert(tasksToInsert, false);

                for (Integer i = 0; i < results.size(); i++) {
                    if (!results[i].isSuccess()) {
                        for (Database.Error err : results[i].getErrors()) {
                            System.debug('Task insert failed for record ' + tasksToInsert[i].WhatId + ': ' + err.getMessage());
                        }
                    }
                }
            }

            // Send emails safely — limit 10 per transaction
            if (!emails.isEmpty()) {
                Integer totalEmails = emails.size();
                Integer batchSize = 10;

                for (Integer i = 0; i < totalEmails; i += batchSize) {
                    Integer lastIndex = Math.min(i + batchSize, totalEmails);
                    List<Messaging.SingleEmailMessage> batch = new List<Messaging.SingleEmailMessage>();

                    
                    for (Integer j = i; j < lastIndex; j++) {
                        batch.add(emails[j]);
                    }

                    try {
                        Messaging.sendEmail(batch);
                    } catch (Exception e) {
                        System.debug('Failed to send email batch starting at index ' + i + ': ' + e.getMessage());
                    }
                }
            }

        } catch (Exception ex) {
            //Clean logging for unexpected errors
            System.debug('Error in handleDeliveredOrders: ' + ex.getMessage());
        }
        
        
        
    }
}