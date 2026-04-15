public class UpdateIsSyncingInvocable {
    @InvocableMethod(label='Clear SyncedQuoteId on Opportunity' description='Clears SyncedQuoteId on Opportunity matching Quote Id')
    public static List<Response> execute(List<Request> requests) {
        List<Response> responses = new List<Response>();

        if (requests == null || requests.isEmpty()) {
            return responses;
        }

        // Collect all quote Ids from requests
        Set<Id> quoteIds = new Set<Id>();
        for (Request req : requests) {
            if (req.quoteId != null) {
                quoteIds.add(req.quoteId);
            }
        }

        if (quoteIds.isEmpty()) {
            // Return error for each request with null quoteId
            for (Request req : requests) {
                Response r = new Response();
                r.success = false;
                r.errorMsg = 'Quote Id is null or empty';
                responses.add(r);
            }
            return responses;
        }

        // Query opportunities with SyncedQuoteId in quoteIds
        List<Opportunity> oppsToUpdate = [
            SELECT Id, SyncedQuoteId
            FROM Opportunity
            WHERE SyncedQuoteId IN :quoteIds
        ];

        // Map quoteId to Opportunities that need update
        Map<Id, Opportunity> quoteIdToOpp = new Map<Id, Opportunity>();
        for (Opportunity opp : oppsToUpdate) {
            quoteIdToOpp.put(opp.SyncedQuoteId, opp);
        }

        // Prepare responses per request
        for (Request req : requests) {
            Response res = new Response();
            if (req.quoteId == null) {
                res.success = false;
                res.errorMsg = 'Quote Id is null or empty';
            } else if (!quoteIdToOpp.containsKey(req.quoteId)) {
                res.success = false;
                res.errorMsg = 'No Opportunity found with SyncedQuoteId = ' + req.quoteId;
            } else {
                Opportunity oppToClear = quoteIdToOpp.get(req.quoteId);
                oppToClear.SyncedQuoteId = null;

                try {
                    update oppToClear;
                    res.success = true;
                    res.errorMsg = null;
                } catch (DmlException e) {
                    res.success = false;
                    res.errorMsg = 'Failed to update Opportunity: ' + e.getMessage();
                }
            }
            responses.add(res);
        }

        return responses;
    }

    public class Request {
        @InvocableVariable(required=true label='Quote Id')
        public Id quoteId;
    }

    public class Response {
        @InvocableVariable(label='Success')
        public Boolean success;

        @InvocableVariable(label='Error Message')
        public String errorMsg;
    }
}