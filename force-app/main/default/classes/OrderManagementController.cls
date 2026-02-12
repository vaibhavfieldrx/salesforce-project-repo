/**
 * @description       : Order Management Controller
 * @author            :
 * @group             :
 * @last modified on  : 02-12-2026
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
            ' ORDER BY EffectiveDate DESC ' +
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

// @AuraEnabled(cacheable=true)
// public static List<Order> getOrdersPendingApproval() {

//     Id userId = UserInfo.getUserId();

//     Set<Id> orderIds = new Set<Id>();

//     for (ProcessInstanceStep step : [
//         SELECT ProcessInstance.TargetObjectId
//         FROM ProcessInstanceStep
//         WHERE StepStatus = 'Started'
//     ]) {
//         orderIds.add(step.ProcessInstance.TargetObjectId);
//     }

//     if (orderIds.isEmpty()) {
//         return new List<Order>();
//     }

//     return [
//         SELECT Id, OrderNumber, Status, CreatedDate
//         FROM Order
//         WHERE Id IN :orderIds
//         ORDER BY CreatedDate DESC
//     ];
// }

@AuraEnabled(cacheable=true)
public static List<Map<String, Object>> getOrdersPendingApproval() {

    Id userId = UserInfo.getUserId();

    List<ProcessInstanceWorkitem> workItems = [
        SELECT
            Id,
            ProcessInstance.TargetObjectId,
            ProcessInstance.CreatedDate
        FROM ProcessInstanceWorkitem
        WHERE ActorId = :userId
        AND ProcessInstance.Status = 'Pending'
    ];

    Set<Id> orderIds = new Set<Id>();
    Map<Id, Id> orderToWorkItem = new Map<Id, Id>();

    for (ProcessInstanceWorkitem wi : workItems) {
        orderIds.add(wi.ProcessInstance.TargetObjectId);
        orderToWorkItem.put(wi.ProcessInstance.TargetObjectId, wi.Id);
    }

    if (orderIds.isEmpty()) {
        return new List<Map<String, Object>>();
    }

    Map<Id, Order> orderMap = new Map<Id, Order>([
        SELECT Id, OrderNumber, Status, CreatedDate
        FROM Order
        WHERE Id IN :orderIds
    ]);

    List<Map<String, Object>> result = new List<Map<String, Object>>();

    for (Id orderId : orderIds) {
        Order o = orderMap.get(orderId);
        if (o != null) {
            result.add(new Map<String, Object>{
                'orderId'    => o.Id,
                'orderNumber'=> o.OrderNumber,
                'status'     => o.Status,
                'createdDate'=> o.CreatedDate,
                'workItemId' => orderToWorkItem.get(orderId) // 🔥 IMPORTANT
            });
        }
    }

    return result;
}



// @AuraEnabled(cacheable=true)
// public static List<Order> getOrdersForSMApproval() {

//     return [
//         SELECT Id, OrderNumber, Status, CreatedDate, Account.Name
//         FROM Order
//         WHERE Status = 'Submitted for Approval'
//         ORDER BY CreatedDate DESC
//     ];
// }

@AuraEnabled(cacheable=true)
public static List<Map<String, Object>> getOrdersForSMApproval() {

    Id userId = UserInfo.getUserId();

    // 1️⃣ Get work items assigned to SM
    List<ProcessInstanceWorkitem> workItems = [
        SELECT
            Id,
            ProcessInstance.TargetObjectId
        FROM ProcessInstanceWorkitem
        WHERE ActorId = :userId
        AND ProcessInstance.Status = 'Pending'
    ];

    if (workItems.isEmpty()) {
        return new List<Map<String, Object>>();
    }

    // 2️⃣ Map OrderId → WorkItemId
    Map<Id, Id> orderToWorkItem = new Map<Id, Id>();
    Set<Id> orderIds = new Set<Id>();

    for (ProcessInstanceWorkitem wi : workItems) {
        orderIds.add(wi.ProcessInstance.TargetObjectId);
        orderToWorkItem.put(wi.ProcessInstance.TargetObjectId, wi.Id);
    }

    // 3️⃣ Fetch Orders
    Map<Id, Order> orders = new Map<Id, Order>([
        SELECT Id, OrderNumber, Status, CreatedDate, Account.Name
        FROM Order
        WHERE Id IN :orderIds
        ORDER BY CreatedDate DESC
    ]);

    // 4️⃣ Build response
    List<Map<String, Object>> result = new List<Map<String, Object>>();

    for (Id orderId : orders.keySet()) {
        Order o = orders.get(orderId);
        result.add(new Map<String, Object>{
            'orderId'     => o.Id,
            'orderNumber' => o.OrderNumber,
            'status'      => o.Status,
            'createdDate' => o.CreatedDate,
            'accountName' => o.Account.Name,
            'workItemId'  => orderToWorkItem.get(orderId) // 🔥 IMPORTANT
        });
    }

    return result;
}


//  @AuraEnabled
//     public static void approveOrder(Id orderId) {

//         ProcessInstanceWorkitem wi = [
//             SELECT Id
//             FROM ProcessInstanceWorkitem
//             WHERE ProcessInstance.TargetObjectId = :orderId
//             LIMIT 1
//         ];

//         Approval.ProcessWorkitemRequest req =
//             new Approval.ProcessWorkitemRequest();

//         req.setWorkitemId(wi.Id);
//         req.setAction('Approve');
//         req.setComments('Approved by SM');

//         Approval.process(req);
//     }

@AuraEnabled
public static void approveOrder(String workItemId, String comment) {

    if (String.isBlank(workItemId)) {
        throw new AuraHandledException('WorkItemId is required');
    }

    Approval.ProcessWorkitemRequest req =
        new Approval.ProcessWorkitemRequest();

    req.setWorkitemId(workItemId);
    req.setAction('Approve');
    req.setComments(comment);

    Approval.ProcessResult result = Approval.process(req);

    if (!result.isSuccess()) {
        throw new AuraHandledException('Approval failed');
    }
}



    @AuraEnabled
    public static void rejectOrder(Id orderId) {

        ProcessInstanceWorkitem wi = [
            SELECT Id
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :orderId
            LIMIT 1
        ];

        Approval.ProcessWorkitemRequest req =
            new Approval.ProcessWorkitemRequest();

        req.setWorkitemId(wi.Id);
        req.setAction('Reject');
        req.setComments('Rejected by SM');

        Approval.process(req);
    }


@AuraEnabled(cacheable=true)
public static List<Map<String, Object>> getPendingApprovals() {

    Id userId = UserInfo.getUserId();

    List<ProcessInstanceWorkitem> workItems = [
        SELECT
            Id,
            ProcessInstanceId,
            ProcessInstance.TargetObjectId,
            ProcessInstance.Status,
            ProcessInstance.CreatedDate,
            ProcessInstance.SubmittedBy.Name
        FROM ProcessInstanceWorkitem
        WHERE ActorId = :userId
        AND ProcessInstance.Status = 'Pending'
    ];

    Set<Id> orderIds = new Set<Id>();
    for (ProcessInstanceWorkitem wi : workItems) {
        orderIds.add(wi.ProcessInstance.TargetObjectId);
    }

    Map<Id, Order> orderMap = new Map<Id, Order>([
        SELECT Id, OrderNumber, Status, TotalAmount
        FROM Order
        WHERE Id IN :orderIds
    ]);

    List<Map<String, Object>> result = new List<Map<String, Object>>();

    for (ProcessInstanceWorkitem wi : workItems) {
        Order o = orderMap.get(wi.ProcessInstance.TargetObjectId);
        if (o != null) {
            result.add(new Map<String, Object>{
                'workItemId' => wi.Id,
                'orderId' => o.Id,
                'orderNumber' => o.OrderNumber,
                'status' => o.Status,
                'amount' => o.TotalAmount,
                'submittedBy' => wi.ProcessInstance.SubmittedBy.Name,
                'submittedDate' => wi.ProcessInstance.CreatedDate
            });
        }
    }

    return result;
}




@AuraEnabled
public static String submitOrderForApproval(Id orderId, String comment) {

    if (orderId == null) {
        throw new AuraHandledException('Order Id is required');
    }
    if (String.isBlank(comment)) {
        throw new AuraHandledException('Comment is required.');
    }

    // Check existing approval
    Integer pendingCount = [
        SELECT COUNT()
        FROM ProcessInstance
        WHERE TargetObjectId = :orderId
        AND Status = 'Pending'
    ];

    if (pendingCount > 0) {
        throw new AuraHandledException('Order is already in approval process');
    }

    Order ord = [
        SELECT Id, Status
        FROM Order
        WHERE Id = :orderId
        LIMIT 1
    ];

    if (ord.Status != 'Draft') {
        throw new AuraHandledException('Only Draft orders can be submitted for approval');
    }

    try {
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(orderId);

        // 🔥 IMPORTANT LINE
        req.setProcessDefinitionNameOrId('Order_Approval_Process');

        req.setComments(comment);

        Approval.ProcessResult result = Approval.process(req);

        if (!result.isSuccess()) {
            throw new AuraHandledException('Approval submission failed');
        }

        // Optional – update only if approval process does NOT do it
        ord.Status = 'Submitted for Approval';
        update ord;

        return 'Order submitted for approval successfully';

    } catch (Exception ex) {
        throw new AuraHandledException(ex.getMessage());
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
