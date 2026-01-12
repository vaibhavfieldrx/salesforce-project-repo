public class DailySalesPDFService {

    public static void generatePDFAndSend() {

        PageReference pdfPage = Page.DailySalesReportPDF;
        Blob pdfBlob = pdfPage.getContentAsPDF();

        Messaging.EmailFileAttachment attachment =
            new Messaging.EmailFileAttachment();
        attachment.setFileName('Daily_Sales_Report.pdf');
        attachment.setBody(pdfBlob);

        Messaging.SingleEmailMessage email =
            new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { 'ashwiniv@codeplateau.com' });
        email.setSubject('Daily Sales Report');
        email.setPlainTextBody(
            'Please find attached the daily sales report.'
        );
        email.setFileAttachments(
            new Messaging.EmailFileAttachment[] { attachment }
        );

        Messaging.sendEmail(
            new Messaging.SingleEmailMessage[] { email }
        );
    }
}