/**
 * @description       : Order Management Controller
 * @author            :
 * @group             :
 * @last modified on  : 02-03-2026
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

    /* =====================================================
       ORDER DETAILS
    ===================================================== */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getOrderDetails(Id orderId) {
        Order ord = [
            SELECT Id, OrderNumber, EffectiveDate, TotalAmount,
                   AccountId, Account.Name, Account.Phone,
                   (SELECT Id, Quantity, UnitPrice, TotalPrice,
                           Product2.Name, Product2.StockKeepingUnit
                    FROM OrderItems)
            FROM Order
            WHERE Id = :orderId
            LIMIT 1
        ];

        Contact con;
        if (ord.AccountId != null) {
            con = [
                SELECT Email, Phone
                FROM Contact
                WHERE AccountId = :ord.AccountId
                LIMIT 1
            ];
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
