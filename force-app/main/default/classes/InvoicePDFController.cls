public with sharing class InvoicePDFController {

    public Invoice__c InvoiceRecord { get; private set; }
    public Company_Info__mdt companyInfo { get; private set; }
    public Decimal subTotal { get; set; }
    public Decimal countGst { get; set; }
    public Decimal finalAmount { get; set; }
    public String paymentStatus { get; set; }

    // NEW: Wrapper list to show dynamic table
    public List<LineWrapper> invoiceLines { get; private set; }

    // NEW: Wrapper class for Sr.No + Line Item
    public class LineWrapper {
        public Integer srNo { get; set; }
        public Invoice_line_Item__c line { get; set; }
        public Decimal totalAmount { get; set; }
    }

    public InvoicePDFController(ApexPages.StandardController stdController) {

        Id invId = stdController.getId();

        if (invId != null) {
            InvoiceRecord = [
                SELECT Id, 
                       Invoice_Number__c, 
                       Invoice_Date__c, 
                       Payment_Status__c, 
                       Balance__c,
                       Total_Amount__c, 
                       Total_Tax__c, 
                       Remarks__c,
                	   Order__c,
                       Order__r.OrderNumber, 
                       Customer__r.Name, 
                       Billing_Address__c
                FROM Invoice__c
                WHERE Id = :invId
                LIMIT 1
            ];
        } else {
            InvoiceRecord = (Invoice__c) stdController.getRecord();
        }

        // Load CMDT
        try {
            companyInfo = Company_Info__mdt.getInstance('FieldRx');
        } catch (Exception e) {
            companyInfo = null;
        }

        // ================================
        // NEW: Fetch Invoice Line Items
        // ================================
        invoiceLines = new List<LineWrapper>();

        if (InvoiceRecord != null && InvoiceRecord.Id != null) {
          List<Invoice_line_Item__c> tempList = [
    SELECT 
        Id,
        Product__c,
        Product__r.Name,
        Quantity__c,
        Unit_Price__c,
        Tax_Amount__c
    FROM Invoice_line_Item__c
    WHERE Invoice__c = :InvoiceRecord.Id
    ORDER BY CreatedDate
];


            Integer count = 1;
			System.debug('tempList JSON:: ' + JSON.serializePretty(tempList));
            Decimal subTotalCalc = 0;
            for (Invoice_line_Item__c il : tempList) {
                LineWrapper lw = new LineWrapper();
                lw.srNo = count;
                lw.line = il;
                lw.totalAmount = (il.Unit_Price__c != null ? il.Unit_Price__c : 0) *
                     (il.Quantity__c != null ? il.Quantity__c : 0);
                subTotalCalc += lw.totalAmount;
                invoiceLines.add(lw);
                count++;
            }
            this.subTotal = subTotalCalc;
            this.countGst = subTotalCalc * 0.18;
            this.finalAmount = subTotal - countGst;
        }
    }

    // Getter methods
    public String getCompanyName() {
        return (companyInfo != null && String.isNotBlank(companyInfo.Company_Name__c))
               ? companyInfo.Company_Name__c : 'Company Name';
    }

    public String getCompanyAddress() {
        return (companyInfo != null && String.isNotBlank(companyInfo.Address__c))
               ? companyInfo.Address__c : '';
    }

    public String getCompanyEmail() {
        return (companyInfo != null && String.isNotBlank(companyInfo.Email__c))
               ? companyInfo.Email__c : '';
    }

    public String getCompanyPhone() {
        return (companyInfo != null && String.isNotBlank(companyInfo.Phone__c))
               ? companyInfo.Phone__c : '';
    }
}