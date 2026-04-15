@IsTest
public class CreateQuoteLWCCtrlTest {

    private class QuoteSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"QuoteRef":"Q-12345"}');
            return res;
        }
    }

    private class QuoteErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error":"Bad Request"}');
            return res;
        }
    }

    @IsTest
    static void testPerformAction_Success() {
        
        Test.setMock(HttpCalloutMock.class, new QuoteSuccessMock());

        String recordId = '001000000000001AAA';

        Test.startTest();
        String result = CreateQuoteLWCCtrl.performAction(recordId);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assert(
            result.contains('Success'),
            'Expected success message but got: ' + result
        );
    }

    @IsTest
    static void testPerformAction_ErrorResponse() {
        
        Test.setMock(HttpCalloutMock.class, new QuoteErrorMock());

        String recordId = '001000000000002AAA';

        Test.startTest();
        String result = CreateQuoteLWCCtrl.performAction(recordId);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assert(
            result.contains('Error'),
            'Expected error message but got: ' + result
        );
    }
}