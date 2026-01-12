@isTest
public class FEPerformanceBatchTest {

    @isTest
    static void testBatchExecution() {

        // 1. Create FE User (optional if using existing users)
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        // 2. Create Orders (dummy data)
        List<Order> orders = new List<Order>();
        for(Integer i = 0; i < 10; i++){
            orders.add(new Order(
                Name = 'Test Order ' + i,
                EffectiveDate = Date.today(),
                Status = 'Draft'
            ));
        }
        insert orders;

        // 3. Run Batch
        Test.startTest();
        Database.executeBatch(new FEPerformanceBatch(), 200);
        Test.stopTest();

        // 4. Verify Result
        List<FE_Performance__c> perfList =
            [SELECT Id, Score__c, Order_Number__c FROM FE_Performance__c];

        System.assert(perfList.size() > 0, 'Performance record should be created');
    }
}