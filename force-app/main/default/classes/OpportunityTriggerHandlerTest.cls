@IsTest
private class OpportunityTriggerHandlerTest {

    @IsTest
    static void testDuplicateWithMultiSelectProductType() {
        Id recordTypeIdCustAcc = InstandaUtility.getRecordTypeIdbyName('Account', 'Customer Accounts');
        Account acc = new Account(FirstName = 'Test', LastName = 'Test Account', RecordTypeId = recordTypeIdCustAcc);
        insert acc;

        PricebookEntry pbe = createPricebookEntry('IR35 Standalone', 1020);
        
        Opportunity oppNew = createOpportunity(acc, '99999', '191919', 'Closed Lost', Date.today().addDays(-10), pbe, null, 'Admiral Trades');

        Test.startTest();
        Opportunity opp = createOpportunity(acc, '99999', '191919', 'Prospecting', Date.today().addDays(10), pbe, null, 'Admiral Trades;FUL Trades');
        Test.stopTest();
    }

        @IsTest
    static void testNoDuplicateWhenNoCommonProducts() {
        Id recordTypeIdCustAcc = InstandaUtility.getRecordTypeIdbyName('Account', 'Customer Accounts');
        Account acc = new Account(FirstName = 'Test2' ,LastName = 'Test Account 2', RecordTypeId = recordTypeIdCustAcc);
        insert acc;

        PricebookEntry pbe = createPricebookEntry('IR35 Standalone', 1020);
        
        Opportunity oppNew = createOpportunity(acc, '99999', '191919', 'Closed Lost', Date.today().addDays(-5), pbe, null, 'Direct Professions;Single Buying Journey');

        Test.startTest();
        Opportunity opp = createOpportunity(acc, '99999', '191919', 'Prospecting', Date.today().addDays(20), pbe, null, 'IR35 Protect Standalone');
        Test.stopTest();
    }

    private static PricebookEntry createPricebookEntry(String productName, Decimal unitPrice) {
        Product2 pro = new Product2(Name = productName, isActive = true);
        insert pro;

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = pro.Id,
            UnitPrice = unitPrice,
            IsActive = true
        );
        insert pbe;
        return pbe;
    }

    private static Opportunity createOpportunity(Account acc, String quoteId, String sbjQuoteId, String stageName, Date closeDate, PricebookEntry pbe, Boolean referred, String productType) {
        Id recordTypeId = InstandaUtility.getRecordTypeIdbyName('Opportunity', 'New Business Opportunity');
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = recordTypeId;
        opp.AccountId = acc.Id;
        opp.Name = 'Test';
        opp.StageName = stageName;
        opp.INSTANDA_Quote_ID__c = quoteId;
        opp.SBJ_Quote_ID__c = sbjQuoteId;
        opp.CloseDate = closeDate;
        opp.Closed_Lost_Date__c = closeDate;
        if (referred != null) opp.Referred__c = referred;
        opp.Product_Type__c = productType;
        insert opp;

        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = opp.Id;
        oli.Quantity = 1;
        oli.PricebookEntryId = pbe.Id;
        oli.TotalPrice = 12;
        insert oli;

        return opp;
    }
}