@IsTest
public class InstandaButtonCompControllerTest {

    @TestSetup
    static void setup() {
        // Insert a default InstandaApi__c record
        InstandaApi__c insApi = new InstandaApi__c(
            Name = 'Default API',
            base_url__c = 'test.instanda.com'
        );
        insert insApi;

        Auto_Number__c aut = new Auto_Number__c();
        aut.Autonumber_Partner_ID__c = 4445;
        insert aut;
    }

    @IsTest
    static void testGenerateURL_Lead() {
        Lead testLead = new Lead(
            LastName = 'Smith',
            FirstName = 'John',
            Email = 'john.smith@example.com',
            Phone = '123456789',
            Occupation__c = 'Engineer',
            Product_Type__c = 'IR35 Protect Standalone',
            Product_Code__c = '12345',
            Company = 'Test Company'
        );
        insert testLead;

        Test.startTest();
        InstandaButtonCompController.DataWrapper result = 
            InstandaButtonCompController.generateURL(testLead.Id, 'Lead');
        Test.stopTest();
    }

    @IsTest
    static void testGenerateURL_Account() {
        Account testAcc = new Account(
            Name = 'Test Account'
        );
        insert testAcc;

        Contact dummyContact = new Contact(
            FirstName = 'Lukasz',
            LastName = 'Zawieja',
            Email = 'lukasz.zawieja@gmail.com'
        );
        insert dummyContact;

        Test.startTest();
        InstandaButtonCompController.DataWrapper result = 
            InstandaButtonCompController.generateURL(testAcc.Id, 'Account');
        Test.stopTest();
    }

    @IsTest
    static void testGenerateURL_Opportunity() {
        Id recordTypeIdCustAcc = InstandaUtility.getRecordTypeIdbyName('Account', 'Customer Accounts');
        Account acc = new Account(FirstName = 'Test', LastName = 'Test Account', RecordTypeId = recordTypeIdCustAcc);
        insert acc;

        Contact dummyContact = new Contact(
            FirstName = 'Lukasz',
            LastName = 'Zawieja',
            Email = 'lukasz.zawieja@gmail.com'
        );
        insert dummyContact;

        PricebookEntry pbe = createPricebookEntry('IR35 Standalone', 1020);
        
        Opportunity oppNew = createOpportunity(acc, '99999', '191919', 'Closed Lost', Date.today().addDays(-10), pbe, null, 'Admiral Trades');

        Test.startTest();
        InstandaButtonCompController.DataWrapper result = 
            InstandaButtonCompController.generateURL(oppNew.Id, 'Opportunity');
        Test.stopTest();
    }

    @IsTest
    static void testGenerateURL_Case() {
        Id recordTypeIdCustAcc = InstandaUtility.getRecordTypeIdbyName('Account', 'Customer Accounts');
        Account acc = new Account(FirstName = 'Test', LastName = 'Test Account', RecordTypeId = recordTypeIdCustAcc);
        insert acc;

        Contact dummyContact = new Contact(
            FirstName = 'Lukasz',
            LastName = 'Zawieja',
            Email = 'lukasz.zawieja@gmail.com'
        );
        insert dummyContact;

        PricebookEntry pbe = createPricebookEntry('IR35 Standalone', 1020);
        
        Opportunity oppNew = createOpportunity(acc, '99999', '191919', 'Closed Lost', Date.today().addDays(-10), pbe, null, 'Admiral Trades');

        Case testCase = new Case(
            AccountId = acc.Id,
            Opportunity__c = oppNew.Id,
            Subject = 'Test Case'
        );
        insert testCase;

        Test.startTest();
        InstandaButtonCompController.DataWrapper result = 
            InstandaButtonCompController.generateURL(testCase.Id, 'Case');
        Test.stopTest();
    }

    @IsTest
    static void testGenerateURL_Policy() {
        Account customer = new Account(
            Name = 'Policy Customer'
        );
        insert customer;

        Contact dummyContact = new Contact(
            FirstName = 'Lukasz',
            LastName = 'Zawieja',
            Email = 'lukasz.zawieja@gmail.com'
        );
        insert dummyContact;

        Policy__c policy = new Policy__c(
            Name = 'Test Policy',
            Customer__c = customer.Id,
            INSTANDA_Quote_ID__c = 'P789'
        );
        insert policy;

        Test.startTest();
        InstandaButtonCompController.DataWrapper result = 
            InstandaButtonCompController.generateURL(policy.Id, 'Policy__c');
        Test.stopTest();
    }

    @IsTest
    static void testGenerateURLLead2() {
        Lead leadRecord = new Lead(
            LastName = 'Doe',
            Email = 'lead2@example.com',
            INSTANDA_Quote_ID__c = 'L321',
            Company = 'CompanyX'
        );
        insert leadRecord;

        Test.startTest();
        InstandaButtonCompController.DataWrapper result = 
            InstandaButtonCompController.generateURLLead2(leadRecord.Id);
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