@IsTest
private class UpsertLeadsAPITest {

    private static void setupApiKey(String apiKey) {
        InstandaApi__c cs = InstandaApi__c.getOrgDefaults();
        if (cs == null) {
            cs = new InstandaApi__c();
        }
        cs.api_key__c = apiKey;
        upsert cs;
    }

    private static String buildRequestBody() {
        UpsertLeadsAPI.RequestHandler req = new UpsertLeadsAPI.RequestHandler();
        req.QuoteRef = 'Q-12345';
        req.PolicyNumber = 'POL-001';
        req.PackageName = 'Test Package';
        req.PackageCode = 'PKG-01';
        req.PackageIdentifier = 1;
        req.SaleStage = 'New';
        req.IsMTA = false;
        req.PolicyholderFirstName = 'John';
        req.PolicyholderLastName = 'Doe';
        req.PolicyholderEmail = 'john.doe@test.com';
        req.BusinessName = 'Test Business Ltd';
        req.TotalPremium = 1000;
        req.TotalPayable = 1200;

        return JSON.serialize(req);
    }

    @IsTest
    static void testProcessRecords_Success() {
        String apiKey = 'valid-api-key';
        setupApiKey(apiKey);

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/upsertLeads/';
        req.addHeader('api-key', apiKey);
        req.requestBody = Blob.valueOf(buildRequestBody());

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        UpsertLeadsAPI.processRecords();
        Test.stopTest();

    }

    @IsTest
    static void testProcessRecords_Unauthorized() {
        setupApiKey('correct-key');

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/upsertLeads/';
        req.addHeader('api-key', 'wrong-key');
        req.requestBody = Blob.valueOf(buildRequestBody());

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        UpsertLeadsAPI.processRecords();
        Test.stopTest();

        System.assertEquals(401, RestContext.response.statusCode);
    }

    @IsTest
    static void testProcessRecords_Forbidden() {
        setupApiKey('some-key');

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/upsertLeads/';
        req.requestBody = Blob.valueOf(buildRequestBody());

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        UpsertLeadsAPI.processRecords();
        Test.stopTest();

        System.assertEquals(403, RestContext.response.statusCode);
    }
}