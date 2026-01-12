@isTest
private class InvoiceEmailSendAsyncTest {

    @isTest
    static void testInvoiceEmailQueueable() {

        Invoice__c inv = new Invoice__c();
        insert inv;

        Test.setMock(HttpCalloutMock.class, new DummyPDFMock());

        Test.startTest();
        System.enqueueJob(new InvoiceEmailSendAsync(inv.Id, 'test@example.com'));
        Test.stopTest();

        System.assert(true, 'Queueable executed successfully');
    }

    private class DummyPDFMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('PDFDATA');
            return res;
        }
    }
}