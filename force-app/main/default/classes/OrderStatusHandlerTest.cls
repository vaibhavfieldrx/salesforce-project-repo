@isTest
public class OrderStatusHandlerTest {

    @isTest
    public static void testCorrectOtp() {
        // Order with correct OTP
        Order ord = new Order(
            Name = 'Test Order',
            Status = 'Pending',
            OTP__c = '1234',
            Generated_OTP__c = '1234'
        );
        insert ord;

        // Run handler
        Test.startTest();
        OrderStatusHandler.setStatusBasedOnOtp(new List<Order>{ ord });
        Test.stopTest();

        // Validate Status Updated
        System.assertEquals('Delivered', ord.Status, 'Status should update when OTP matches');
    }

    @isTest
    public static void testIncorrectOtp() {

        // Order with wrong OTP
        Order ord = new Order(
            Name = 'Wrong OTP Order',
            Status = 'Pending',
            OTP__c = '9999',
            Generated_OTP__c = '1234'
        );

        Test.startTest();
        try {
            OrderStatusHandler.setStatusBasedOnOtp(new List<Order>{ ord });
            System.assert(false, 'Exception should occur for wrong OTP');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('incorrect'));
        }
        Test.stopTest();
    }


    @isTest
    public static void testBlankOtp() {
        // OTP not entered
        Order ord = new Order(
            Name = 'Blank OTP Order',
            Status = 'Shipped',
            OTP__c = null,
            Generated_OTP__c = '1234'
        );
        insert ord;

        Test.startTest();
        OrderStatusHandler.setStatusBasedOnOtp(new List<Order>{ ord });
        Test.stopTest();

        // Should remain unchanged
        System.assertEquals('Shipped', ord.Status, 'Status must remain same when OTP not entered');
    }


    @isTest
    public static void testAlreadyDelivered() {
        // Already delivered order
        Order ord = new Order(
            Name = 'Delivered Order',
            Status = 'Delivered',
            OTP__c = '1111',
            Generated_OTP__c = '1111'
        );
        insert ord;

        Test.startTest();
        OrderStatusHandler.setStatusBasedOnOtp(new List<Order>{ ord });
        Test.stopTest();

        // Should still be delivered
        System.assertEquals('Delivered', ord.Status);
    }


    @isTest
    public static void testMultipleOrders() {
        Order o1 = new Order(
            Name = 'Order1',
            Status = 'Pending',
            OTP__c = '123',
            Generated_OTP__c = '123'
        );
        Order o2 = new Order(
            Name = 'Order2',
            Status = 'Pending',
            OTP__c = '000',
            Generated_OTP__c = '111'
        );
        insert new List<Order>{ o1, o2 };

        Test.startTest();
        try {
            OrderStatusHandler.setStatusBasedOnOtp(new List<Order>{ o1, o2 });
        } catch (Exception e) {
            // Expected for o2 wrong OTP
        }
        Test.stopTest();

        // Validate first order became delivered
        System.assertEquals('Delivered', o1.Status);

        // Second order should throw error; handler addError prevents status change
        System.assertEquals('Pending', o2.Status);
    }
}