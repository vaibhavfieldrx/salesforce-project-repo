public with sharing class OrderdetailController {
    public Order OrderRecord { get; private set; }
    public Company_Info__mdt companyInfo { get; private set; }
    public List<OrderItem> orderItems { get; private set; }
    public List<LineItemWrapper> orderItemWrappers { get; private set; }
    public Decimal orderItemsTotal { get; private set; }
    public Decimal totalTax { get; private set; }
    public Decimal grandTotal { get; private set; }
     
    public class LineItemWrapper {
        public Integer index { get; set; }
        public OrderItem lineItem { get; set; }
        public LineItemWrapper(Integer idx, OrderItem li) {
            this.index = idx;
            this.lineItem = li;
        }
    }
 
    public OrderdetailController(ApexPages.StandardController stdController) {
        Id ordId = (Id) stdController.getId();
 
        orderItems = new List<OrderItem>();
        orderItemWrappers = new List<LineItemWrapper>();
        orderItemsTotal = 0;
        totalTax = 0;
        grandTotal = 0;
 
        if (ordId != null) {
            OrderRecord = [
                SELECT Id, OrderNumber, EffectiveDate, Status, TotalAmount, AccountId, Account.Name,
                       BillingAddress, ShippingAddress
                FROM Order
                WHERE Id = :ordId
                LIMIT 1
            ];
 
            orderItems = [
                SELECT Id, OrderId, PricebookEntryId,
                       PricebookEntry.Product2Id, PricebookEntry.Product2.Name,
                       Quantity, UnitPrice, TotalPrice, ServiceDate, Tax_Amount__c
                FROM OrderItem
                WHERE OrderId = :ordId
                ORDER BY CreatedDate
            ];
 
            Integer idx = 0;
            for (OrderItem li : orderItems) {
                idx++;
                orderItemWrappers.add(new LineItemWrapper(idx, li));
                orderItemsTotal += (li.TotalPrice == null ? 0 : li.TotalPrice);
                totalTax += (li.Tax_Amount__c== null ? 0 : li.Tax_Amount__c);
            } // For indexing & calc. Total Amount
            
            // Compute grand total: use Order.TotalAmount if present, otherwise sum of line totals
            Decimal baseTotal = (OrderRecord != null && OrderRecord.TotalAmount != null) ? OrderRecord.TotalAmount : orderItemsTotal;
            grandTotal = (baseTotal == null ? 0 : baseTotal) + (totalTax == null ? 0 : totalTax);
            
        } else {
            OrderRecord = (Order) stdController.getRecord();
        }
 
        try {
            companyInfo = Company_Info__mdt.getInstance('FieldRx');
        } catch (Exception e) {
            companyInfo = null;
            System.debug('Company Info not found: ' + e.getMessage());
        }
    }
 
    public String getCompanyName() {
        return companyInfo != null && String.isNotBlank(companyInfo.Company_Name__c) 
               ? companyInfo.Company_Name__c : 'Company Name';
    }
 
    public String getCompanyAddress() {
        return companyInfo != null && String.isNotBlank(companyInfo.Address__c) 
               ? companyInfo.Address__c : '';
    }
 
    public String getCompanyEmail() {
        return companyInfo != null && String.isNotBlank(companyInfo.Email__c) 
               ? companyInfo.Email__c : '';
    }
 
    public String getCompanyPhone() {
        return companyInfo != null && String.isNotBlank(companyInfo.Phone__c) 
               ? companyInfo.Phone__c : '';
    }
 
    public Boolean getHasLineItems() {
        return orderItemWrappers != null && !orderItemWrappers.isEmpty();
    }
    
    public String getFormattedOrderItemsTotal() {
        if (orderItemsTotal == null) return '0.00';
        return String.valueOf(orderItemsTotal.setScale(2));
    }
    
    public String getFormattedTotalTax() {
    return totalTax == null ? '0.00' : String.valueOf(totalTax.setScale(2));
    }
    
    public String getFormattedGrandTotal() {
        if (grandTotal == null) return '0.00';
        return String.valueOf(grandTotal.setScale(2));
    }

}