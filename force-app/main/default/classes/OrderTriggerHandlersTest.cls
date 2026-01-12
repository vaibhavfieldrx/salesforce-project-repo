@isTest
private class OrderTriggerHandlersTest {

    // Helper: get a Profile Id for user creation
    private static Id getAnyProfileId() {
        // Try standard user; fallback to first profile available
        List<Profile> ps = [SELECT Id, Name FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        if (!ps.isEmpty()) return ps[0].Id;
        return [SELECT Id FROM Profile LIMIT 1].Id;
    }

    // Helper: create a test user
    private static User createTestUser(String uniqueSuffix, Boolean isActive) {
        Id profId = getAnyProfileId();
        User u = new User(
            Username = 'testuser_' + uniqueSuffix + '@example.com',
            Alias = 'tusr' + uniqueSuffix.substring(0, Math.min(4, uniqueSuffix.length())),
            Email = 'testuser_' + uniqueSuffix + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Tester',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Kolkata',
            ProfileId = profId,
            IsActive = isActive
        );
        insert u;
        return u;
    }

    // Main test: creates supporting data, then updates Order to Delivered and asserts Task created
    @isTest static void testDeliveredOrderCreatesFollowUpTask() {
        // Create Account
        Account acct = new Account(Name = 'Test Account - Order Trigger');
        insert acct;

        // Create a user to act as owner and an FE user
        String uniq = String.valueOf(Math.abs(Crypto.getRandomInteger()));
        User orderOwner = createTestUser('owner' + uniq, true);
        User feUser = createTestUser('fe' + uniq, true);

        // Create Field Executive record (custom object). If your org has different API names, adjust.
        Field_Executive__c fe = new Field_Executive__c(
            Field_Executive_Name__c = 'Test FE',
            Email__c = 'fe+' + uniq + '@example.com',
            User__c = feUser.Id
        );
        insert fe;

        // Optional: create Contract (some orgs require Contract on Order)
        Contract c;
        try {
            c = new Contract(AccountId = acct.Id, StartDate = System.today(), Status = 'Draft');
            insert c;
        } catch (Exception ex) {
            // If Contract isn't required or not allowed, ignore
            c = null;
        }

        // Create Order with many common fields to satisfy typical triggers & validation rules.
        Order ord = new Order();
        ord.AccountId = acct.Id;
        ord.EffectiveDate = System.today();
        ord.Status = 'Draft';           // adjust if your org uses different statuses
        ord.OwnerId = orderOwner.Id;
        if (c != null) ord.ContractId = c.Id;

        // If your org requires a Pricebook/Product/OrderItem to be present, create them:
        // create product, active standard pricebook entry and order item (optional)
        Product2 prod;
        Pricebook2 stdPB;
        PricebookEntry pbe;
        try {
            prod = new Product2(Name = 'Test Product ' + uniq, IsActive = true);
            insert prod;

            stdPB = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];

            pbe = new PricebookEntry(Product2Id = prod.Id, Pricebook2Id = stdPB.Id,
                                     UnitPrice = 10, IsActive = true);
            insert pbe;

            // Make Order as 'Activated' might require OrderItems; but we'll not create OrderItem unless needed.
        } catch (Exception e) {
            // ignore if your org setup disallows product/pricebook modifications in tests
        }

        // Insert order
        insert ord;

        // Now set to Delivered and assign FE
        ord.Status = 'Delivered';
        ord.Field_Executive__c = fe.Id;

        // Try update inside Test.start/stop so trigger runs in test context.
        Test.startTest();
        try {
            update ord;
        } catch (DmlException dmEx) {
            // Clear and show a helpful error so you can add missing fields to this test
            // Fail the test with clear message
            Test.stopTest();
            System.assert(false,
                'Order update failed in test. DML exception: ' + dmEx.getMessage() +
                '\nIf OrderNumberTrigger or a validation requires additional fields, add them to the test. ' +
                'Full exception: ' + dmEx.getDmlMessage(0)
            );
            return; // keep compiler happy
        } finally {
            Test.stopTest();
        }

        // Query for Task created by your FEfollowUpTaskOrderTrigger -> OrderTriggerHandlers
        List<Task> tasks = [
            SELECT Id, WhatId, OwnerId, Subject, Status, Priority, ActivityDate
            FROM Task
            WHERE WhatId = :ord.Id
        ];

        // Primary assertion: at least one task should have been created
        System.assert(tasks.size() >= 1, 'Expected at least one follow-up Task for delivered order. Found: ' + tasks.size());

        // If FE user is active and was set correctly, the first task owner usually is the FE user
        // But your org logic may vary, so we assert Task exists and leave owner check optional:
        Boolean foundForFE = false;
        for (Task t : tasks) {
            if (t.OwnerId == feUser.Id) { foundForFE = true; break; }
        }

        // Soft assert: prefer task assigned to FE, but don't fail loudly if your org assigns differently.
        System.assert(foundForFE, 'Expected at least one Task assigned to FE user (' + feUser.Id + '), but none found. Task owners: ' + String.escapeSingleQuotes(String.join(new List<String>(new Set<String>()) , ',')) );
    }
}