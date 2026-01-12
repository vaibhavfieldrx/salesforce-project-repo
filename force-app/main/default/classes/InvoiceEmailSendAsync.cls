public class InvoiceEmailSendAsync implements Queueable, Database.AllowsCallouts {

    private String invoiceId;
    private String toEmail;

    public InvoiceEmailSendAsync(String invoiceId, String toEmail) {
        this.invoiceId = invoiceId;
        this.toEmail = toEmail;
    }

    public void execute(QueueableContext qc) {
        try {
            PageReference pdfPage = Page.InvoicePDFPage;
            pdfPage.getParameters().put('id', invoiceId);

            System.debug('Generating PDF...');
            Blob pdfBody = pdfPage.getContentAsPDF();

            Messaging.EmailFileAttachment file = new Messaging.EmailFileAttachment();
            file.setFileName('Invoice.pdf');
            file.setBody(pdfBody);

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[]{ toEmail });
            mail.setSubject('Invoice PDF');
            mail.setPlainTextBody('Please find the attached invoice.');
            mail.setFileAttachments(new Messaging.EmailFileAttachment[]{ file });

            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ mail });

            System.debug('Email Sent Successfully');

        } catch (Exception e) {
            System.debug('Error in Queueable: ' + e.getMessage());
        }
    }
}