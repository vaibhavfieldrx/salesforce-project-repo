public with sharing class OrderManagementController {

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDashboardData(
        Integer pageSize,
        Integer pageNumber,
        String searchKey,
        String status
    ) {

        Integer offsetVal = (pageNumber - 1) * pageSize;

        /* =========================
           🔹 DYNAMIC WHERE CLAUSE
        ========================== */
        String whereClause = ' WHERE Id != null ';

        if (!String.isBlank(searchKey)) {
            whereClause += ' AND Account.Name LIKE \'%' +
                String.escapeSingleQuotes(searchKey) + '%\'';
        }

        if (!String.isBlank(status)) {
            whereClause += ' AND Status = :status';
        }

        /* =========================
           🔹 ORDERS (TABLE DATA)
        ========================== */
        String orderQuery =
            'SELECT Id, OrderNumber, Status, TotalAmount, EffectiveDate, Account.Name ' +
            'FROM Order ' +
            whereClause +
            ' ORDER BY CreatedDate DESC ' +
            ' LIMIT :pageSize OFFSET :offsetVal';

        List<Order> orders = Database.query(orderQuery);

        /* =========================
           🔹 TOTAL COUNT (PAGINATION)
        ========================== */
        String countQuery =
            'SELECT COUNT() FROM Order ' + whereClause;

        Integer totalOrders = Database.countQuery(countQuery);

        /* =========================
           🔹 ORDER SUMMARY (RIGHT PANEL)
           ⚠️ Summary should NOT be filtered
        ========================== */
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

        /* =========================
           🔹 ANNUAL / TOTAL REVENUE
           ⚠️ No filter, no pagination
        ========================== */
        Decimal revenue = 0;
        AggregateResult rev = [
            SELECT SUM(TotalAmount) total
            FROM Order
            WHERE Status != 'Draft'
        ];
        if (rev.get('total') != null) {
            revenue = (Decimal) rev.get('total');
        }

        /* =========================
           🔹 FINAL RESPONSE
        ========================== */
        return new Map<String, Object>{
            'orders' => orders,
            'totalOrders' => totalOrders,
            'summary' => summary,
            'revenue' => revenue
        };
    }
}
