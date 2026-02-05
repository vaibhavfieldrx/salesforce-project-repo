/**
 * @description       : Order Management Controller
 * @author            :
 * @group             :
 * @last modified on  : 02-04-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class OrderManagementController {

    /* =====================================================
       DASHBOARD DATA
    ===================================================== */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDashboardData(
        Integer pageSize,
        Integer pageNumber,
        String searchKey,
        String status
    ) {
        Integer offsetVal = (pageNumber - 1) * pageSize;

        String whereClause = ' WHERE Id != null ';

        if (!String.isBlank(searchKey)) {
            whereClause += ' AND Account.Name LIKE \'%' +
                String.escapeSingleQuotes(searchKey) + '%\'';
        }

        if (!String.isBlank(status)) {
            whereClause += ' AND Status = :status';
        }

        String orderQuery =
            'SELECT Id, OrderNumber, Status, TotalAmount, EffectiveDate, Account.Name ' +
            'FROM Order ' +
            whereClause +
            ' ORDER BY CreatedDate DESC ' +
            ' LIMIT :pageSize OFFSET :offsetVal';

        List<Order> orders = Database.query(orderQuery);

        Integer totalOrders = Database.countQuery(
            'SELECT COUNT() FROM Order ' + whereClause
        );

        Map<String, Integer> summary = new Map<String, Integer>();
        for (AggregateResult ar : [
            SELECT Status, COUNT(Id) cnt
            FROM Order
            GROUP BY Status
        ]) {
            summary.put(
                (String) ar.get('Status'),
                (Integer) ar.get('cnt')
            );
        }

        Decimal revenue = 0;
        AggregateResult rev = [
            SELECT SUM(TotalAmount) total
            FROM Order
            WHERE Status != 'Draft'
        ];
        if (rev.get('total') != null) {
            revenue = (Decimal) rev.get('total');
        }

        return new Map<String, Object>{
            'orders' => orders,
            'totalOrders' => totalOrders,
            'summary' => summary,
            'revenue' => revenue
        };
    }


@AuraEnabled
public static String submitOrderForApproval(Id orderId, String comment) {
    if (orderId == null) throw new AuraHandledException('Order Id is required');
    if (String.isBlank(comment)) throw new AuraHandledException('Comment is required.');

    try {
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(orderId);
        req.setComments(comment);

        // Initial approver is determined by your Approval Process
        // Salesforce will follow your defined steps automatically
        Approval.ProcessResult result = Approval.process(req);

        if (!result.isSuccess()) {
            throw new AuraHandledException('Approval submission failed: ' + result.getErrors());
        }
        return 'Order submitted for approval successfully';
    } catch(Exception ex) {
        throw new AuraHandledException('Error: ' + ex.getMessage());
    }
}



    /* =====================================================
       ORDER DETAILS
    ===================================================== */
    @AuraEnabled(cacheable=true)
public static Map<String, Object> getOrderDetails(Id orderId) {
    Order ord = [
        SELECT Id, OrderNumber, EffectiveDate, TotalAmount, ShippingAddress, Status,
               AccountId, Account.Name, Account.Phone, Account.Email__c,
               (SELECT Id, Quantity, UnitPrice, TotalPrice,
                       Product2.Name, Product2.StockKeepingUnit
                FROM OrderItems)
        FROM Order
        WHERE Id = :orderId
        LIMIT 1
    ];

    Contact con;
    if (ord.AccountId != null) {
        List<Contact> cons = [
            SELECT Email, Phone
            FROM Contact
            WHERE AccountId = :ord.AccountId
            LIMIT 1
        ];
        if (!cons.isEmpty()) {
            con = cons[0];
        }
    }

    return new Map<String, Object>{
        'order' => ord,
        'contact' => con
    };
}

    /* =====================================================
       DELETE ORDER  ✅ FIXED
    ===================================================== */
    @AuraEnabled
    public static void deleteOrder(Id orderId) {
        if (orderId == null) {
            throw new AuraHandledException('Order Id is required');
        }

        Order ord = [
            SELECT Id, Status
            FROM Order
            WHERE Id = :orderId
            LIMIT 1
        ];

        // Optional safety rule
        if (ord.Status != 'Draft') {
            throw new AuraHandledException(
                'Only Draft orders can be deleted'
            );
        }

        try {
            delete ord;
        } catch (DmlException e) {
            throw new AuraHandledException(
                'Unable to delete order. ' + e.getMessage()
            );
        }
    }

    /* =====================================================
       SUPPORT METHODS
    ===================================================== */
    @AuraEnabled(cacheable=true)
    public static List<Account> getCustomers() {
        return [
            SELECT Id, Name
            FROM Account
            ORDER BY Name
            LIMIT 200
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Account getCustomerDetails(Id customerId) {
        return [
            SELECT Name, BillingAddress, Email__c
            FROM Account
            WHERE Id = :customerId
            LIMIT 1
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Warehouse__c> getWarehouses() {
        return [
            SELECT Id, Name
            FROM Warehouse__c
            ORDER BY Name
        ];
    }
}
