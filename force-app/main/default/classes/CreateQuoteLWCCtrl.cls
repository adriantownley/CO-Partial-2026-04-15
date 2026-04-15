public with sharing class CreateQuoteLWCCtrl {

    @AuraEnabled(cacheable=false)
    public static String performAction(String recordId) {
        system.debug('***recordId = ' + recordId);

        String returnStr = '';

        try {
            //call customsetting or metadata

            String endpointURL = '';
            system.debug('***endpointURL = ' + endpointURL);

            String reqBody = '';
            QuoteRequestWrapper req = new QuoteRequestWrapper();
            req.name = 'test';
            reqBody = JSON.serialize(req);
            system.debug('***reqBody = ' + reqBody);

            HttpResponse httpResp = postRequest(endpointURL, reqBody);
            System.debug('***httpResp code: ' + httpResp.getStatusCode());
            System.debug('***httpResp body: ' + httpResp.getBody());

            if(httpResp.getStatusCode() == 200){
                QuoteResponseWrapper quoteDetails = (QuoteResponseWrapper) JSON.deserialize(httpResp.getBody(), QuoteResponseWrapper.class);
                system.debug('***quoteDetails = ' + quoteDetails);

                //Populate/update record fields

                returnStr = 'Success: Quote created.';
            }else{
                returnStr = 'Error: ' + httpResp.getStatusCode() + ' - ' + httpResp.getBody();
                
            }

            return returnStr;
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

     public static HttpResponse postRequest(String endpoint, String requestBody){
        HTTPResponse response;

        HttpRequest httpReq = new HttpRequest();
        httpReq.setMethod('POST');
        httpReq.setEndPoint(endpoint);
        httpReq.setBody(requestBody);
        httpReq.setHeader('Content-Type' , 'application/json');
        httpReq.setHeader('Accept', 'application/json');

        Http http = new Http();
        response = http.send(httpReq);

        return response;
    }

    public class QuoteResponseWrapper {
        public String QuoteRef;
    }

    public class QuoteRequestWrapper{
        public String name;
    }
}