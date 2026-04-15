@IsTest
public class UpdateIsSyncingInvocableTest {

    @IsTest
    static void testExecute_successfulUpdate() {
        
        Auto_Number__c aut = new Auto_Number__c();
        aut.Autonumber_Partner_ID__c = 4445;
        insert aut;

        Id recordTypeIdCustAcc = InstandaUtility.getRecordTypeIdbyName('Account', 'Customer Accounts');
        Account acc = new Account(FirstName = 'Test', LastName = 'Test Account', RecordTypeId = recordTypeIdCustAcc);
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        Quote q = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'Draft'
        );
        insert q;

        opp.SyncedQuoteId = q.Id;
        update opp;

        UpdateIsSyncingInvocable.Request req = new UpdateIsSyncingInvocable.Request();
        req.quoteId = q.Id;

        List<UpdateIsSyncingInvocable.Request> requests =
            new List<UpdateIsSyncingInvocable.Request>{ req };

        Test.startTest();
        List<UpdateIsSyncingInvocable.Response> responses =
            UpdateIsSyncingInvocable.execute(requests);
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(true, responses[0].success);
        System.assertEquals(null, responses[0].errorMsg);

        Opportunity updatedOpp = [
            SELECT SyncedQuoteId
            FROM Opportunity
            WHERE Id = :opp.Id
        ];
        System.assertEquals(null, updatedOpp.SyncedQuoteId);
    }

    @IsTest
    static void testExecute_nullQuoteId() {

        UpdateIsSyncingInvocable.Request req = new UpdateIsSyncingInvocable.Request();
        req.quoteId = null;

        List<UpdateIsSyncingInvocable.Request> requests =
            new List<UpdateIsSyncingInvocable.Request>{ req };

        Test.startTest();
        List<UpdateIsSyncingInvocable.Response> responses =
            UpdateIsSyncingInvocable.execute(requests);
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(false, responses[0].success);
        System.assertEquals(
            'Quote Id is null or empty',
            responses[0].errorMsg
        );
    }

    @IsTest
    static void testExecute_noMatchingOpportunity() {
        Auto_Number__c aut = new Auto_Number__c();
        aut.Autonumber_Partner_ID__c = 4445;
        insert aut;

        Id recordTypeIdCustAcc = InstandaUtility.getRecordTypeIdbyName('Account', 'Customer Accounts');
        Account acc = new Account(FirstName = 'Test', LastName = 'Test Account', RecordTypeId = recordTypeIdCustAcc);
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp 2',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        Quote q = new Quote(
            Name = 'Orphan Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'Draft'
        );
        insert q;

        UpdateIsSyncingInvocable.Request req = new UpdateIsSyncingInvocable.Request();
        req.quoteId = q.Id;

        List<UpdateIsSyncingInvocable.Request> requests =
            new List<UpdateIsSyncingInvocable.Request>{ req };

        Test.startTest();
        List<UpdateIsSyncingInvocable.Response> responses =
            UpdateIsSyncingInvocable.execute(requests);
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(false, responses[0].success);
        System.assert(
            responses[0].errorMsg.contains('No Opportunity found with SyncedQuoteId'),
            'Expected error message for missing Opportunity'
        );
    }

    @IsTest
    static void testExecute_mixedRequests() {

        Auto_Number__c aut = new Auto_Number__c();
        aut.Autonumber_Partner_ID__c = 4445;
        insert aut;

        Id recordTypeIdCustAcc = InstandaUtility.getRecordTypeIdbyName('Account', 'Customer Accounts');
        Account acc = new Account(FirstName = 'Test', LastName = 'Test Account', RecordTypeId = recordTypeIdCustAcc);
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Mixed Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        Quote q = new Quote(
            Name = 'Mixed Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'Draft'
        );
        insert q;

        opp.SyncedQuoteId = q.Id;
        update opp;

        UpdateIsSyncingInvocable.Request validReq = new UpdateIsSyncingInvocable.Request();
        validReq.quoteId = q.Id;

        UpdateIsSyncingInvocable.Request nullReq = new UpdateIsSyncingInvocable.Request();
        nullReq.quoteId = null;

        List<UpdateIsSyncingInvocable.Request> requests =
            new List<UpdateIsSyncingInvocable.Request>{ validReq, nullReq };

        Test.startTest();
        List<UpdateIsSyncingInvocable.Response> responses =
            UpdateIsSyncingInvocable.execute(requests);
        Test.stopTest();

        System.assertEquals(2, responses.size());

        System.assertEquals(true, responses[0].success);
        System.assertEquals(false, responses[1].success);
        System.assertEquals(
            'Quote Id is null or empty',
            responses[1].errorMsg
        );
    }
}