global class StockAgingBatch implements Database.Batchable<SObject>, Database.Stateful {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Query all Stock Ledger records that need aging calculation
        return Database.getQueryLocator([
            SELECT Id, CreatedDate, 
                   Product_In__c, Product_Out__c,
                   X0_3_IN__c, X0_3_OUT__c,
                   X3_6_IN__c, X3_6_OUT__c,
                   X6_9_IN__c, X6_9_OUT__c,
                   X9_12_IN__c, X9_12_OUT__c,
                   More_Than_12_Months_IN__c, More_Than_12_Months_OUT__c,
                   More_Than_24_Months_IN__c, More_Than_24_Months_OUT__c
            FROM Stock_Ledger__c
            WHERE CreatedDate != NULL
        ]);
    }
    global void execute(Database.BatchableContext bc, List<Stock_Ledger__c> scope) {
        Date today = Date.today();
 
        for (Stock_Ledger__c s : scope) {
            // Calculate months difference
            Integer months = today.monthsBetween(s.CreatedDate.date());
 
            // Reset all checkboxes
            s.X0_3_IN__c = false;
            s.X0_3_OUT__c = false;
            s.X3_6_IN__c = false;
            s.X3_6_OUT__c = false;
            s.X6_9_IN__c = false;
            s.X6_9_OUT__c = false;
            s.X9_12_IN__c = false;
            s.X9_12_OUT__c = false;
            s.More_Than_12_Months_IN__c = false;
            s.More_Than_12_Months_OUT__c = false;
            s.More_Than_24_Months_IN__c = false;
            s.More_Than_24_Months_OUT__c = false;
 
            // Determine IN/OUT
            Boolean isIn = s.Product_In__c != null && s.Product_In__c > 0;
            Boolean isOut = s.Product_Out__c != null && s.Product_Out__c > 0;
 
            if (isIn) {
                if (months <= 3) s.X0_3_IN__c = true;
                else if (months <= 6) s.X3_6_IN__c = true;
                else if (months <= 9) s.X6_9_IN__c = true;
                else if (months <= 12) s.X9_12_IN__c = true;
                else if (months <= 24) s.More_Than_12_Months_IN__c = true;
                else s.More_Than_24_Months_IN__c = true;
            }
 
            if (isOut) {
                if (months <= 3) s.X0_3_OUT__c = true;
                else if (months <= 6) s.X3_6_OUT__c = true;
                else if (months <= 9) s.X6_9_OUT__c = true;
                else if (months <= 12) s.X9_12_OUT__c = true;
                else if (months <= 24) s.More_Than_12_Months_OUT__c = true;
                else s.More_Than_24_Months_OUT__c = true;
            }
        }
 
        update scope;
    }
 
    global void finish(Database.BatchableContext bc) {
        System.debug('Stock Aging Batch completed successfully.');
    }
}