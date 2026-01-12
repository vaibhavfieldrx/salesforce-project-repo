public with sharing class OrderReassignmentService {

    // Input for Flow
    public class Request {
        @InvocableVariable(required=true) public Id feFromId;
        @InvocableVariable(required=true) public Id feToId;
    }

    // Output for Flow
    public class Result {
        @InvocableVariable public Integer updatedCount;
        @InvocableVariable public Integer failedCount;
        @InvocableVariable public List<String> errors;
        @InvocableVariable public String resultMessage; // formatted message for Flow
    }

    @InvocableMethod(label='Reassign Orders')
    public static List<Result> reassignOrders(List<Request> requests) {

        List<Result> results = new List<Result>();

        if(requests == null || requests.isEmpty()) return results;

        for(Request req : requests) {

            Result res = new Result();
            res.updatedCount = 0;
            res.failedCount = 0;
            res.errors = new List<String>();
            res.resultMessage = '';

            // Default pending statuses
            List<String> statuses = new List<String>{'Draft','Submitted for Approval','Approved','Pending'};

            // Validation
            if(req.feFromId == req.feToId || req.feFromId == null || req.feToId == null) {
                res.errors.add('Invalid FE selection.');
                res.resultMessage = 'Invalid FE selection. Please select different FEs.';
                results.add(res);
                continue;
            }

            // Query pending orders assigned to FE1
            List<Order> ordersToUpdate = [
                SELECT Id, Field_Executive__c, Status
                FROM Order
                WHERE Field_Executive__c = :req.feFromId
                  AND Status IN :statuses
            ];

            // Update Field_Executive__c to FE2
            for(Order o : ordersToUpdate) {
                o.Field_Executive__c = req.feToId;
            }

            // Bulk update with partial success
            if(!ordersToUpdate.isEmpty()) {
                Database.SaveResult[] srs = Database.update(ordersToUpdate, false);
                for(Integer i = 0; i < srs.size(); i++){
                    if(srs[i].isSuccess()) res.updatedCount++;
                    else {
                        res.failedCount++;
                        for(Database.Error err : srs[i].getErrors()) {
                            res.errors.add('OrderId:'+ordersToUpdate[i].Id+' - '+err.getMessage());
                        }
                    }
                }
            }

            // Format result message
            res.resultMessage = 'Orders reassigned: ' + res.updatedCount + 
                                '. Failed: ' + res.failedCount + 
                                (res.failedCount > 0 ? '. Errors: ' + String.join(res.errors, '; ') : '');

            results.add(res);
        }

        return results;
    }
}