@isTest
private class TransactionAPITest {
    // Test Setup to insert common data once
    @testSetup
    static void setupTestData() {
        InstandaApi__c api = new InstandaApi__c();
        api.api_key__c = '123456';
        api.close_date_add_days__c = '2';
        api.last_assigned_index__c = '1';
        insert api;

        Kingsbridge_General_Custom_Setting__c vr = new Kingsbridge_General_Custom_Setting__c();
        vr.Validation_Rule__c = true;
        insert vr;

        Auto_Number__c autoNum = new Auto_Number__c();
        autoNum.Autonumber_Partner_ID__c = 1;
        insert autoNum;
    }

    // Helper method to create Account
    private static Account createAccount(String email) {
        Account acc = new Account();
        acc.FirstName = 'Test';
        acc.LastName = 'Last';
        acc.PersonEmail = email;
        insert acc;
        return acc;
    }

    // Helper method to create Product, Pricebook and PricebookEntry
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

    // Helper method to create Opportunity and OpportunityLineItem
    private static Opportunity createOpportunity(Account acc, String quoteId, String sbjQuoteId, String stageName, Date closeDate, PricebookEntry pbe, Boolean referred) {
        Id recordTypeId = InstandaUtility.getRecordTypeIdbyName('Opportunity', 'New Business Opportunity');
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = recordTypeId;
        opp.AccountId = acc.Id;
        opp.Name = 'Test';
        opp.StageName = stageName;
        opp.INSTANDA_Quote_ID__c = quoteId;
        opp.SBJ_Quote_ID__c = sbjQuoteId;
        opp.CloseDate = closeDate;
        if (referred != null) opp.Referred__c = referred;
        insert opp;

        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = opp.Id;
        oli.Quantity = 1;
        oli.PricebookEntryId = pbe.Id;
        oli.TotalPrice = 12;
        insert oli;

        return opp;
    }

    // Helper method to create Policy
    private static Policy__c createPolicy(Opportunity opp, String policyId, String status) {
        Policy__c pol = new Policy__c();
        pol.Status__c = status;
        pol.From_Opportunity__c = opp.Id;
        pol.INSTANDA_Policy_ID__c = policyId;
        insert pol;
        return pol;
    }

    // Helper method to setup RestRequest context and call TransactionAPI.processRecords()
    private static void executePayload(String payloadJSON, Map<String, String> headers, Map<String, String> params) {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(payloadJSON);

        if (headers != null) {
            for (String headerName : headers.keySet()) {
                request.addHeader(headerName, headers.get(headerName));
            }
        }

        if (params != null) {
            for (String paramName : params.keySet()) {
                request.addParameter(paramName, params.get(paramName));
            }
        }

        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        TransactionAPI.processRecords();
        Test.stopTest();
    }

    // ====== Validation Methods ======

    @isTest static void apiKeyIsIncorrect() {
        String payloadJSON = '{"QuoteRef":"88888","SBJQuoteRef":""}';

        Map<String, String> headers = new Map<String, String>{ 'api-key' => '83' };
        executePayload(payloadJSON, headers, null);
    }

    @isTest static void apiKeyIsNotSupplied() {
        String payloadJSON = '{"QuoteRef":"88888","SBJQuoteRef":""}';

        Map<String, String> headers = new Map<String, String>{ 'ced-test' => '123456' };
        executePayload(payloadJSON, headers, null);
    }

    @isTest static void errorJson() {
        String payloadJSON = '"QuoteRef":"88888","SBJQuoteRef":""}';

        Map<String, String> headers = new Map<String, String>{ 'api-key' => '123456' };
        executePayload(payloadJSON, headers, null);
    }

    // ====== Part 1 Test Methods ======

    @isTest static void newLead() {
        Account acc = new Account(Name = 'SampleAcc');
        insert acc;

        String payloadJSON = '{"QuoteRef":"88888","SBJQuoteRef":"","PolicyNumber":"","PackageName":"Direct Professions","PackageCode":"","PackageIdentifier":1,"CreatedOn":"2024-01-01","QuoteDate":"2024-01-01","EffectiveFromDate":"2024-01-01T23:00:00","EffectiveUntilDate":"2024-01-01T23:00:00","ExpiryDateTime":"","SaleStage":"CancelQuote","CreatedFrom":"NewBusiness","IsProfessions":false,"IsSme":false,"IsWholesaleSite":false,"IsDirectSite":false,"WasReferred":false,"IsDetailChange":false,"IsMTA":false,"IsRenewal":false,"QuoteStartedByAgentGroupName":"","QuoteStartedBySalesPersonName":"","SalespersonEmail":"","SalespersonName":"","AgentGroupEmail":"","AgentGroupName":"","IsBrokerAgent":false,"IsKingsbridgeAgent":false,"ProfessionalIndemnityCoverLevel":1,"PublicLiabilityCoverLevel":1,"PackageIncludesPersonalAccident":"","PersonalAccidentCoverLevel":"","PersonalAccidentDeathBenefit":"","PersonalAccidentWeeklyBenefit":"","BusinessEquipmentCoverLevel":"","BusinessEquipmentLimit":"","BusinessEquipmentLimitOfCoverRequired":1,"DirectorsAndOfficersCoverLevel":"","EmployersLiabilityCover":1,"PolicyholderTitle":"Mr.","PolicyholderFirstName":"Cedric","PolicyholderLastName":"Demo","PolicyholderEmail":"test123@test.com","PolicyholderPhone":"09123223453","PolicyholderDateOfBirth":"1991-01-01","PolicyholderAddressLine1":"1","PolicyholderCity":"London","PolicyholderCountry":"UK","PolicyholderPostcode":"STK 123","BusinessName":"SampleB","BusinessType":"","CompanyStatus":"","PrimaryBusinessActivity":"","Sector":"","HasSecondaryActivity":false,"Turnover":"","NumberOfFeeEarningEmployees":1,"PriceReductionType":"","DiscountAmount":1,"PremiumAdjustment":1,"PricematchPremium":1,"TotalPremium":null,"IptAmount":1,"TotalPayable":1,"ReleaseDate":"2024-01-01","PackageBuildTag":"","PageSubmitted_Page1":"","PageSubmitted_Page2":"","PageSubmitted_Page5":"","PageSubmitted_Page8":"","PageSubmitted_QuickQuote":"","PageSubmitted_Quote":"","SiteEnvironment":"","SiteName":"","SiteType":"","PartnerCompanyOther":"SampleAcc"}';

        Map<String, String> headers = new Map<String, String>{ 'api-key' => '123456' };
        executePayload(payloadJSON, headers, null);
    }

    @isTest static void existingLeadByEmail() {
        Lead ld = new Lead(FirstName = 'Test', LastName = 'Last', Email = 'yyyyyy@test.com', INSTANDA_Quote_ID__c = '0957367', Product_Type__c = 'Direct Professions');
        insert ld;

        Account acc = new Account(Name = 'SampleAcc');
        insert acc;

        String payloadJSON = '{"QuoteRef":"0957367","SBJQuoteRef":"","PolicyNumber":"","PackageName":"Direct Professions","PackageCode":"","PackageIdentifier":1,"CreatedOn":"2024-01-01","QuoteDate":"2024-01-01","EffectiveFromDate":"2024-01-01T23:00:00","EffectiveUntilDate":"2024-01-01T23:00:00","ExpiryDateTime":"","SaleStage":"CancelQuote","CreatedFrom":"NewBusiness","IsProfessions":false,"IsSme":false,"IsWholesaleSite":false,"IsDirectSite":false,"WasReferred":false,"IsDetailChange":false,"IsMTA":false,"IsRenewal":false,"QuoteStartedByAgentGroupName":"","QuoteStartedBySalesPersonName":"","SalespersonEmail":"","SalespersonName":"","AgentGroupEmail":"","AgentGroupName":"","IsBrokerAgent":false,"IsKingsbridgeAgent":false,"ProfessionalIndemnityCoverLevel":1,"PublicLiabilityCoverLevel":1,"PackageIncludesPersonalAccident":"","PersonalAccidentCoverLevel":"","PersonalAccidentDeathBenefit":"","PersonalAccidentWeeklyBenefit":"","BusinessEquipmentCoverLevel":"","BusinessEquipmentLimit":"","BusinessEquipmentLimitOfCoverRequired":1,"DirectorsAndOfficersCoverLevel":"","EmployersLiabilityCover":1,"PolicyholderTitle":"Mr.","PolicyholderFirstName":"Cedric","PolicyholderLastName":"Y","PolicyholderEmail":"yyyyyy@test.com","PolicyholderPhone":"09123223453","PolicyholderDateOfBirth":"1991-01-01","PolicyholderAddressLine1":"1","PolicyholderCity":"London","PolicyholderCountry":"UK","PolicyholderPostcode":"STK 123","BusinessName":"SampleB","BusinessType":"","CompanyStatus":"","PrimaryBusinessActivity":"","Sector":"","HasSecondaryActivity":false,"Turnover":"","NumberOfFeeEarningEmployees":1,"PriceReductionType":"","DiscountAmount":1,"PremiumAdjustment":1,"PricematchPremium":1,"TotalPremium":123,"IptAmount":1,"TotalPayable":1,"ReleaseDate":"2024-01-01","PackageBuildTag":"","PageSubmitted_Page1":"","PageSubmitted_Page2":"","PageSubmitted_Page5":"","PageSubmitted_Page8":"","PageSubmitted_QuickQuote":"","PageSubmitted_Quote":"","SiteEnvironment":"","SiteName":"","SiteType":"","PartnerCompanyOther":"SampleAcc"}';

        Map<String, String> headers = new Map<String, String>{ 'api-key' => '123456' };
        executePayload(payloadJSON, headers, null);
    }

    @isTest static void existingOppSBJ() {
        Lead ld = new Lead(FirstName = 'Test', LastName = 'Last', Email = 'mmjth@sfdc.co', Phone = '123456', Street = 'Street', City = 'City', PostalCode = '3000', Country = 'UK', Product_Type__c = 'Direct Professions');
        insert ld;
        
        Account acc = new Account(FirstName = 'Test', LastName = 'Last', PersonEmail = 'yyyyyy@test.com');
        insert acc;

        PricebookEntry pbe = createPricebookEntry('IR35 Standalone', 1020);

        Opportunity opp = createOpportunity(acc, '99999', '191919', 'Prospecting', Date.today().addDays(-30), pbe, null);
        opp.Name = 'Single Buying Journey';
        update opp;

        Attribution__c att = new Attribution__c();
        att.Name = 'SME - Direct Professions - 99999 - New Business Opportunity';
        insert att;

        String payloadJSON = '{"QuoteRef":"99999","SBJQuoteRef":"191919","PolicyNumber":"","PackageName":"Direct Professions","PackageCode":"","PackageIdentifier":26644,"CreatedOn":"2024-01-01","QuoteDate":"2024-01-01","EffectiveFromDate":"2024-01-01T23:00:00","EffectiveUntilDate":"2024-01-01T23:00:00","ExpiryDateTime":"","SaleStage":"CancelQuote","CreatedFrom":"NewBusiness","IsProfessions":false,"IsSme":true,"IsWholesaleSite":false,"IsDirectSite":false,"WasReferred":false,"IsDetailChange":false,"IsMTA":false,"IsRenewal":false,"QuoteStartedByAgentGroupName":"","QuoteStartedBySalesPersonName":"","SalespersonEmail":"","SalespersonName":"","AgentGroupEmail":"","AgentGroupName":"","IsBrokerAgent":false,"IsKingsbridgeAgent":false,"ProfessionalIndemnityCoverLevel":1,"PublicLiabilityCoverLevel":1,"PackageIncludesPersonalAccident":"","PersonalAccidentCoverLevel":"","PersonalAccidentDeathBenefit":"","PersonalAccidentWeeklyBenefit":"","BusinessEquipmentCoverLevel":"","BusinessEquipmentLimit":"","BusinessEquipmentLimitOfCoverRequired":1,"DirectorsAndOfficersCoverLevel":"","EmployersLiabilityCover":1,"PolicyholderTitle":"Mr.","PolicyholderFirstName":"Cedric","PolicyholderLastName":"Demo","PolicyholderEmail":"mmjth@sfdc.co","PolicyholderPhone":"09123223453","PolicyholderDateOfBirth":"1991-01-01","PolicyholderAddressLine1":"1","PolicyholderCity":"London","PolicyholderCountry":"UK","PolicyholderPostcode":"STK 123","BusinessName":"SampleB","BusinessType":"","CompanyStatus":"","PrimaryBusinessActivity":"","Sector":"","HasSecondaryActivity":false,"Turnover":"","NumberOfFeeEarningEmployees":1,"PriceReductionType":"","DiscountAmount":1,"PremiumAdjustment":1,"PricematchPremium":1,"TotalPremium":123,"IptAmount":1,"TotalPayable":1,"ReleaseDate":"2024-01-01","PackageBuildTag":"","PageSubmitted_Page1":"","PageSubmitted_Page2":"","PageSubmitted_Page5":"","PageSubmitted_Page8":"","PageSubmitted_QuickQuote":"","PageSubmitted_Quote":"","SiteEnvironment":"","SiteName":"","SiteType":""}';

        Map<String, String> headers = new Map<String, String>{ 'api-key' => '123456' };
        executePayload(payloadJSON, headers, null);
    }

    @isTest static void noMatchingOpp() {
        Lead ld = new Lead(FirstName = 'Test', LastName = 'Last', Email = 'mmjth@sfdc.co', Phone = '123456', Street = 'Street', City = 'City', PostalCode = '3000', Country = 'UK', Product_Type__c = 'Direct Professions');
        insert ld;

        ld.Status = 'Unqualified';
        update ld;

        Account acc = createAccount('mmjth@sfdc.co');
        PricebookEntry pbe = createPricebookEntry('Direct Professions', 1020);

        String payloadJSON = '{"QuoteRef":"988282","SBJQuoteRef":"","PolicyNumber":"","PackageName":"Direct Professions","PackageCode":"","PackageIdentifier":26644,"CreatedOn":"2024-01-01","QuoteDate":"2024-01-01","EffectiveFromDate":"2024-01-01T23:00:00","EffectiveUntilDate":"2024-01-01T23:00:00","ExpiryDateTime":"","SaleStage":"CancelQuote","CreatedFrom":"NewBusiness","IsProfessions":false,"IsSme":true,"IsWholesaleSite":false,"IsDirectSite":false,"WasReferred":false,"IsDetailChange":false,"IsMTA":false,"IsRenewal":false,"QuoteStartedByAgentGroupName":"","QuoteStartedBySalesPersonName":"","SalespersonEmail":"","SalespersonName":"","AgentGroupEmail":"","AgentGroupName":"","IsBrokerAgent":false,"IsKingsbridgeAgent":false,"ProfessionalIndemnityCoverLevel":1,"PublicLiabilityCoverLevel":1,"PackageIncludesPersonalAccident":"","PersonalAccidentCoverLevel":"","PersonalAccidentDeathBenefit":"","PersonalAccidentWeeklyBenefit":"","BusinessEquipmentCoverLevel":"","BusinessEquipmentLimit":"","BusinessEquipmentLimitOfCoverRequired":1,"DirectorsAndOfficersCoverLevel":"","EmployersLiabilityCover":1,"PolicyholderTitle":"Mr.","PolicyholderFirstName":"Cedric","PolicyholderLastName":"Demo","PolicyholderEmail":"mmjth@sfdc.co","PolicyholderPhone":"09123223453","PolicyholderDateOfBirth":"1991-01-01","PolicyholderAddressLine1":"1","PolicyholderCity":"London","PolicyholderCountry":"UK","PolicyholderPostcode":"STK 123","BusinessName":"SampleB","BusinessType":"","CompanyStatus":"","PrimaryBusinessActivity":"","Sector":"","HasSecondaryActivity":false,"Turnover":"","NumberOfFeeEarningEmployees":1,"PriceReductionType":"","DiscountAmount":1,"PremiumAdjustment":1,"PricematchPremium":1,"TotalPremium":123,"IptAmount":1,"TotalPayable":1,"ReleaseDate":"2024-01-01","PackageBuildTag":"","PageSubmitted_Page1":"","PageSubmitted_Page2":"","PageSubmitted_Page5":"","PageSubmitted_Page8":"","PageSubmitted_QuickQuote":"","PageSubmitted_Quote":"","SiteEnvironment":"","SiteName":"","SiteType":""}';

        Map<String, String> headers = new Map<String, String>{ 'api-key' => '123456' };
        executePayload(payloadJSON, headers, null);
    }

    @isTest static void noMatchingOpp2() {
        Lead ld = new Lead(FirstName = 'Test', LastName = 'Last', Email = 'mmjth@sfdc.co', Phone = '123456', Street = 'Street', City = 'City', PostalCode = '3000', Country = 'UK', Product_Type__c = 'Direct Professions');
        insert ld;

        Account acc = createAccount('mmjth@sfdc.co');
        PricebookEntry pbe = createPricebookEntry('Direct Professions', 1020);

        String payloadJSON = '{"QuoteRef":"988282","SBJQuoteRef":"","PolicyNumber":"","PackageName":"Direct Professions","PackageCode":"","PackageIdentifier":26644,"CreatedOn":"2024-01-01","QuoteDate":"2024-01-01","EffectiveFromDate":"2024-01-01T23:00:00","EffectiveUntilDate":"2024-01-01T23:00:00","ExpiryDateTime":"","SaleStage":"CancelQuote","CreatedFrom":"NewBusiness","IsProfessions":false,"IsSme":true,"IsWholesaleSite":false,"IsDirectSite":false,"WasReferred":false,"IsDetailChange":false,"IsMTA":false,"IsRenewal":false,"QuoteStartedByAgentGroupName":"","QuoteStartedBySalesPersonName":"","SalespersonEmail":"","SalespersonName":"","AgentGroupEmail":"","AgentGroupName":"","IsBrokerAgent":false,"IsKingsbridgeAgent":false,"ProfessionalIndemnityCoverLevel":1,"PublicLiabilityCoverLevel":1,"PackageIncludesPersonalAccident":"","PersonalAccidentCoverLevel":"","PersonalAccidentDeathBenefit":"","PersonalAccidentWeeklyBenefit":"","BusinessEquipmentCoverLevel":"","BusinessEquipmentLimit":"","BusinessEquipmentLimitOfCoverRequired":1,"DirectorsAndOfficersCoverLevel":"","EmployersLiabilityCover":1,"PolicyholderTitle":"Mr.","PolicyholderFirstName":"Cedric","PolicyholderLastName":"Demo","PolicyholderEmail":"mmjth@sfdc.co","PolicyholderPhone":"09123223453","PolicyholderDateOfBirth":"1991-01-01","PolicyholderAddressLine1":"1","PolicyholderCity":"London","PolicyholderCountry":"UK","PolicyholderPostcode":"STK 123","BusinessName":"SampleB","BusinessType":"","CompanyStatus":"","PrimaryBusinessActivity":"","Sector":"","HasSecondaryActivity":false,"Turnover":"","NumberOfFeeEarningEmployees":1,"PriceReductionType":"","DiscountAmount":1,"PremiumAdjustment":1,"PricematchPremium":1,"TotalPremium":123,"IptAmount":1,"TotalPayable":1,"ReleaseDate":"2024-01-01","PackageBuildTag":"","PageSubmitted_Page1":"","PageSubmitted_Page2":"","PageSubmitted_Page5":"","PageSubmitted_Page8":"","PageSubmitted_QuickQuote":"","PageSubmitted_Quote":"","SiteEnvironment":"","SiteName":"","SiteType":"","PaymentType":"Card","PaymentTypeName":"Own","WhereHeard":"My friend","WhereHeardFriendName":"Ced","WhereHeardFriendEmail":"test@234.com"}';

        Map<String, String> headers = new Map<String, String>{ 'api-key' => '123456' };
        executePayload(payloadJSON, headers, null);
    }

    @isTest static void noMatchingOpp3() {
        Lead ld = new Lead(FirstName = 'Test', LastName = 'Last', Email = 'mmjth@sfdc.co', Phone = '123456', Street = 'Street', City = 'City', PostalCode = '3000', Country = 'UK', Product_Type__c = 'Direct Professions');
        insert ld;

        Account acc = createAccount('mmjth@sfdc.co');
        PricebookEntry pbe = createPricebookEntry('Direct Professions', 1020);

        String payloadJSON = '{"QuoteRef":"988282","SBJQuoteRef":"","PolicyNumber":"","PackageName":"Direct Professions","PackageCode":"","PackageIdentifier":26644,"CreatedOn":"2024-01-01","QuoteDate":"2024-01-01","EffectiveFromDate":"2024-01-01T23:00:00","EffectiveUntilDate":"2024-01-01T23:00:00","ExpiryDateTime":"","SaleStage":"CancelQuote","CreatedFrom":"NewBusiness","IsProfessions":false,"IsSme":true,"IsWholesaleSite":false,"IsDirectSite":false,"WasReferred":false,"IsDetailChange":false,"IsMTA":false,"IsRenewal":false,"QuoteStartedByAgentGroupName":"","QuoteStartedBySalesPersonName":"","SalespersonEmail":"","SalespersonName":"","AgentGroupEmail":"","AgentGroupName":"","IsBrokerAgent":false,"IsKingsbridgeAgent":false,"ProfessionalIndemnityCoverLevel":1,"PublicLiabilityCoverLevel":1,"PackageIncludesPersonalAccident":"","PersonalAccidentCoverLevel":"","PersonalAccidentDeathBenefit":"","PersonalAccidentWeeklyBenefit":"","BusinessEquipmentCoverLevel":"","BusinessEquipmentLimit":"","BusinessEquipmentLimitOfCoverRequired":1,"DirectorsAndOfficersCoverLevel":"","EmployersLiabilityCover":1,"PolicyholderTitle":"Mr.","PolicyholderFirstName":"Cedric","PolicyholderLastName":"Demo","PolicyholderEmail":"mmjth@sfdc.co","PolicyholderPhone":"09123223453","PolicyholderDateOfBirth":"1991-01-01","PolicyholderAddressLine1":"1","PolicyholderCity":"London","PolicyholderCountry":"UK","PolicyholderPostcode":"STK 123","BusinessName":"SampleB","BusinessType":"","CompanyStatus":"","PrimaryBusinessActivity":"","Sector":"","HasSecondaryActivity":false,"Turnover":"","NumberOfFeeEarningEmployees":1,"PriceReductionType":"","DiscountAmount":1,"PremiumAdjustment":1,"PricematchPremium":1,"TotalPremium":123,"IptAmount":1,"TotalPayable":1,"ReleaseDate":"2024-01-01","PackageBuildTag":"","PageSubmitted_Page1":"","PageSubmitted_Page2":"","PageSubmitted_Page5":"","PageSubmitted_Page8":"","PageSubmitted_QuickQuote":"","PageSubmitted_Quote":"","SiteEnvironment":"","SiteName":"","SiteType":"","PaymentType":"Card","PaymentTypeName":"Own","WhereHeard":"Accountancy/recruitment company/professional body","WhereHeardPartnerPerson":"Ced","WhereHeardFriendEmail":"test@234.com"}';

        Map<String, String> headers = new Map<String, String>{ 'api-key' => '123456' };
        executePayload(payloadJSON, headers, null);
    }

    @isTest static void noMatchingOpp4() {
        Lead ld = new Lead(FirstName = 'Test', LastName = 'Last', Email = 'mmjth@sfdc.co', Phone = '123456', Street = 'Street', City = 'City', PostalCode = '3000', Country = 'UK', Product_Type__c = 'Direct Professions');
        insert ld;

        Account acc = createAccount('mmjth@sfdc.co');
        PricebookEntry pbe = createPricebookEntry('IR35 Protect Standalone', 1020);

        String payloadJSON = '{"QuoteRef":"988282","SBJQuoteRef":"","PolicyNumber":"","PackageName":"IR35 Protect Standalone","PackageCode":"","PackageIdentifier":26644,"CreatedOn":"2024-01-01","QuoteDate":"2024-01-01","EffectiveFromDate":"2024-01-01T23:00:00","EffectiveUntilDate":"2024-01-01T23:00:00","ExpiryDateTime":"","SaleStage":"CancelQuote","CreatedFrom":"NewBusiness","IsProfessions":false,"IsSme":true,"IsWholesaleSite":false,"IsDirectSite":false,"WasReferred":false,"IsDetailChange":false,"IsMTA":false,"IsRenewal":false,"QuoteStartedByAgentGroupName":"","QuoteStartedBySalesPersonName":"","SalespersonEmail":"","SalespersonName":"","AgentGroupEmail":"","AgentGroupName":"","IsBrokerAgent":false,"IsKingsbridgeAgent":false,"ProfessionalIndemnityCoverLevel":1,"PublicLiabilityCoverLevel":1,"PackageIncludesPersonalAccident":"","PersonalAccidentCoverLevel":"","PersonalAccidentDeathBenefit":"","PersonalAccidentWeeklyBenefit":"","BusinessEquipmentCoverLevel":"","BusinessEquipmentLimit":"","BusinessEquipmentLimitOfCoverRequired":1,"DirectorsAndOfficersCoverLevel":"","EmployersLiabilityCover":1,"PolicyholderTitle":"Mr.","PolicyholderFirstName":"Cedric","PolicyholderLastName":"Demo","PolicyholderEmail":"mmjth@sfdc.co","PolicyholderPhone":"09123223453","PolicyholderDateOfBirth":"1991-01-01","PolicyholderAddressLine1":"1","PolicyholderCity":"London","PolicyholderCountry":"UK","PolicyholderPostcode":"STK 123","BusinessName":"SampleB","BusinessType":"","CompanyStatus":"","PrimaryBusinessActivity":"","Sector":"","HasSecondaryActivity":false,"Turnover":"","NumberOfFeeEarningEmployees":1,"PriceReductionType":"","DiscountAmount":1,"PremiumAdjustment":1,"PricematchPremium":1,"TotalPremium":123,"IptAmount":1,"TotalPayable":1,"ReleaseDate":"2024-01-01","PackageBuildTag":"","PageSubmitted_Page1":"","PageSubmitted_Page2":"","PageSubmitted_Page5":"","PageSubmitted_Page8":"","PageSubmitted_QuickQuote":"","PageSubmitted_Quote":"","SiteEnvironment":"","SiteName":"","SiteType":"","PaymentType":"Card","PaymentTypeName":"Own","WhereHeard":"my employer/client","WhereHeardEmployerClientPerson":"Ced","WhereHeardFriendEmail":"test@234.com"}';

        Map<String, String> headers = new Map<String, String>{ 'api-key' => '123456' };
        executePayload(payloadJSON, headers, null);
    }

    // ====== Part 2 Test Methods ======

    @isTest static void newPolicy() {
        Account acc = createAccount('mmjth@sfdc.co');
        PricebookEntry pbe = createPricebookEntry('Direct Professions', 1020);
        Opportunity opp = createOpportunity(acc, '54321', '', 'Prospecting', Date.today().addDays(-30), pbe, null);

        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id, Quantity = 1, PricebookEntryId = pbe.Id, TotalPrice = 12);
        insert oli;

        String payloadJSON = '{"QuoteRef":"54321","SBJQuoteRef":"","PolicyNumber":"983493","PackageName":"Direct Professions","PackageCode":"","PackageIdentifier":1,"CreatedOn":"2024-01-01","QuoteDate":"2024-01-01","EffectiveFromDate":"2024-01-01T23:00:00","EffectiveUntilDate":"2024-01-01T23:00:00","ExpiryDateTime":"","SaleStage":"Live","CreatedFrom":"NewBusiness","IsProfessions":false,"IsSme":false,"IsWholesaleSite":false,"IsDirectSite":false,"WasReferred":false,"IsDetailChange":false,"IsMTA":false,"IsRenewal":false,"IsRenewalAllowedToLapse":false,"QuoteStartedByAgentGroupName":"","QuoteStartedBySalesPersonName":"","SalespersonEmail":"","SalespersonName":"","AgentGroupEmail":"","AgentGroupName":"","IsBrokerAgent":false,"IsKingsbridgeAgent":false,"ProfessionalIndemnityCoverLevel":1,"PublicLiabilityCoverLevel":1,"PackageIncludesPersonalAccident":"","PersonalAccidentCoverLevel":"","PersonalAccidentDeathBenefit":"","PersonalAccidentWeeklyBenefit":"","BusinessEquipmentCoverLevel":"","BusinessEquipmentLimit":"","BusinessEquipmentLimitOfCoverRequired":1,"DirectorsAndOfficersCoverLevel":"","EmployersLiabilityCover":1,"PolicyholderTitle":"Mr.","PolicyholderFirstName":"Cedric","PolicyholderLastName":"Demo","PolicyholderEmail":"mmjth@sfdc.co","PolicyholderPhone":"09123223453","PolicyholderDateOfBirth":"1991-01-01","PolicyholderAddressLine1":"1","PolicyholderCity":"London","PolicyholderCountry":"UK","PolicyholderPostcode":"STK 123","BusinessName":"SampleB","BusinessType":"","CompanyStatus":"","PrimaryBusinessActivity":"","Sector":"","HasSecondaryActivity":false,"Turnover":"","NumberOfFeeEarningEmployees":1,"PriceReductionType":"","DiscountAmount":1,"PremiumAdjustment":1,"PricematchPremium":1,"TotalPremium":123,"IptAmount":1,"TotalPayable":1,"ReleaseDate":"2024-01-01","PackageBuildTag":"","PageSubmitted_Page1":"","PageSubmitted_Page2":"","PageSubmitted_Page5":"","PageSubmitted_Page8":"","PageSubmitted_QuickQuote":"","PageSubmitted_Quote":"","SiteEnvironment":"","SiteName":"","SiteType":"","PaymentType":"Card","PaymentTypeName":"Own","WhereHeard":"My friend","WhereHeardFriendName":"Ced","WhereHeardFriendEmail":"test@234.com"}';

        Map<String, String> headers = new Map<String, String>{ 'api-key' => '123456' };
        executePayload(payloadJSON, headers, null);
    }

    @isTest static void existingPolicyRenewal() {
        Account acc = createAccount('lukasz.zawieja@gmail.com');
        PricebookEntry pbe = createPricebookEntry('IR35 Standalone', 1020);
        Opportunity opp = createOpportunity(acc, '54321', '', 'Prospecting', Date.today().addDays(-30), pbe, null);

        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id, Quantity = 1, PricebookEntryId = pbe.Id, TotalPrice = 12);
        insert oli;

        Policy__c pol = createPolicy(opp, '843822', 'Live');

        String payloadJSON = '{"QuoteRef":"54321","SBJQuoteRef":"","PolicyNumber":"843822","PackageName":"Direct Professions","PackageCode":"","PackageIdentifier":1,"CreatedOn":"2024-01-01","QuoteDate":"2024-01-01","EffectiveFromDate":"2024-01-01T23:00:00","EffectiveUntilDate":"2024-01-01T23:00:00","ExpiryDateTime":"","SaleStage":"Live","CreatedFrom":"Renewal","IsProfessions":false,"IsSme":false,"IsWholesaleSite":false,"IsDirectSite":false,"WasReferred":false,"IsDetailChange":false,"IsMTA":false,"IsRenewal":true,"IsRenewalAllowedToLapse":false,"QuoteStartedByAgentGroupName":"","QuoteStartedBySalesPersonName":"","SalespersonEmail":"","SalespersonName":"","AgentGroupEmail":"","AgentGroupName":"","IsBrokerAgent":false,"IsKingsbridgeAgent":false,"ProfessionalIndemnityCoverLevel":1,"PublicLiabilityCoverLevel":1,"PackageIncludesPersonalAccident":"","PersonalAccidentCoverLevel":"","PersonalAccidentDeathBenefit":"","PersonalAccidentWeeklyBenefit":"","BusinessEquipmentCoverLevel":"","BusinessEquipmentLimit":"","BusinessEquipmentLimitOfCoverRequired":1,"DirectorsAndOfficersCoverLevel":"","EmployersLiabilityCover":1,"PolicyholderTitle":"Mr.","PolicyholderFirstName":"Cedric","PolicyholderLastName":"Demo","PolicyholderEmail":"test456@test.com","PolicyholderPhone":"09123223453","PolicyholderDateOfBirth":"1991-01-01","PolicyholderAddressLine1":"1","PolicyholderCity":"London","PolicyholderCountry":"UK","PolicyholderPostcode":"STK 123","BusinessName":"SampleB","BusinessType":"","CompanyStatus":"","PrimaryBusinessActivity":"","Sector":"","HasSecondaryActivity":false,"Turnover":"","NumberOfFeeEarningEmployees":1,"PriceReductionType":"","DiscountAmount":1,"PremiumAdjustment":1,"PricematchPremium":1,"TotalPremium":123,"IptAmount":1,"TotalPayable":1,"ReleaseDate":"2024-01-01","PackageBuildTag":"","PageSubmitted_Page1":"","PageSubmitted_Page2":"","PageSubmitted_Page5":"","PageSubmitted_Page8":"","PageSubmitted_QuickQuote":"","PageSubmitted_Quote":"","SiteEnvironment":"","SiteName":"","SiteType":""}';

        Map<String, String> headers = new Map<String, String>{ 'api-key' => '123456' };
        executePayload(payloadJSON, headers, null);
    }

    @isTest static void policyCancellation() {
        Account acc = createAccount('lukasz.zawieja@gmail.com');
        PricebookEntry pbe = createPricebookEntry('IR35 Standalone', 1020);
        Opportunity opp = createOpportunity(acc, '54321', '', 'Prospecting', Date.today().addDays(-30), pbe, null);

        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id, Quantity = 1, PricebookEntryId = pbe.Id, TotalPrice = 12);
        insert oli;

        Policy__c pol = createPolicy(opp, '843822', 'Live');

        String payloadJSON = '{"PolicyNumber":"843822","TopLevelCancellationReason":"Lubay","IsWholesaleSite": false, "SaleStage": "Cancelled", "CancellationConfirmedDate":"2024-01-01T23:00:00","CancellationEffectiveFromDate":"2024-01-01T23:00:00"}';

        Map<String, String> headers = new Map<String, String>{ 'api-key' => '123456' };
        Map<String, String> params = new Map<String, String>{ 'action' => 'cancellation' };
        executePayload(payloadJSON, headers, params);
    }

    @isTest static void newCaseReferral() {
        Account acc = createAccount('lukasz.zawieja@gmail.com');
        PricebookEntry pbe = createPricebookEntry('IR35 Standalone', 1020);
        Opportunity opp = createOpportunity(acc, '988282', '', 'Prospecting', Date.today().addDays(-30), pbe, null);
        
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id, Quantity = 1, PricebookEntryId = pbe.Id, TotalPrice = 12);
        insert oli;

        Policy__c pol = createPolicy(opp, '843822', 'Live');

        String payloadJSON = '{"QuoteRef":"988282","SBJQuoteRef":"","PolicyNumber":"","PackageName":"Direct Professions","PackageCode":"","PackageIdentifier":1,"CreatedOn":"2024-01-01","QuoteDate":"2024-01-01","EffectiveFromDate":"2024-01-01T23:00:00","EffectiveUntilDate":"2024-01-01T23:00:00","ExpiryDateTime":"","SaleStage":"Referral","CreatedFrom":"Cancellation","IsProfessions":false,"IsSme":false,"IsWholesaleSite":false,"IsDirectSite":false,"WasReferred":false,"IsDetailChange":false,"IsMTA":false,"IsRenewal":false,"QuoteStartedByAgentGroupName":"","QuoteStartedBySalesPersonName":"","SalespersonEmail":"","SalespersonName":"","AgentGroupEmail":"","AgentGroupName":"","IsBrokerAgent":false,"IsKingsbridgeAgent":false,"ProfessionalIndemnityCoverLevel":1,"PublicLiabilityCoverLevel":1,"PackageIncludesPersonalAccident":"","PersonalAccidentCoverLevel":"","PersonalAccidentDeathBenefit":"","PersonalAccidentWeeklyBenefit":"","BusinessEquipmentCoverLevel":"","BusinessEquipmentLimit":"","BusinessEquipmentLimitOfCoverRequired":1,"DirectorsAndOfficersCoverLevel":"","EmployersLiabilityCover":1,"PolicyholderTitle":"Mr.","PolicyholderFirstName":"Cedric","PolicyholderLastName":"Update","PolicyholderEmail":"test123@test.com","PolicyholderPhone":"09123223453","PolicyholderDateOfBirth":"1991-01-01","PolicyholderAddressLine1":"1","PolicyholderCity":"London","PolicyholderCountry":"UK","PolicyholderPostcode":"STK 123","BusinessName":"SampleB","BusinessType":"","CompanyStatus":"","PrimaryBusinessActivity":"","Sector":"","HasSecondaryActivity":false,"Turnover":"","NumberOfFeeEarningEmployees":1,"PriceReductionType":"","DiscountAmount":1,"PremiumAdjustment":1,"PricematchPremium":1,"TotalPremium":null,"IptAmount":1,"TotalPayable":1,"ReleaseDate":"2024-01-01","PackageBuildTag":"","PageSubmitted_Page1":"","PageSubmitted_Page2":"","PageSubmitted_Page5":"","PageSubmitted_Page8":"","PageSubmitted_QuickQuote":"","PageSubmitted_Quote":"","SiteEnvironment":"","SiteName":"","SiteType":"","Referred":true}';

        Map<String, String> headers = new Map<String, String>{ 'api-key' => '123456' };
        executePayload(payloadJSON, headers, null);
    }

    @isTest static void existingCaseReferral() {
        Account acc = createAccount('test123@test.com');
        PricebookEntry pbe = createPricebookEntry('IR35 Standalone', 1020);
        Opportunity opp = createOpportunity(acc, '988282', '', 'Prospecting', Date.today().addDays(-30), pbe, true);

        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id, Quantity = 1, PricebookEntryId = pbe.Id, TotalPrice = 12);
        insert oli;

        String payloadJSON = '{"QuoteRef":"988282","SBJQuoteRef":"","PolicyNumber":"","PackageName":"Direct Professions","PackageCode":"","PackageIdentifier":1,"CreatedOn":"2024-01-01","QuoteDate":"2024-01-01","EffectiveFromDate":"2024-01-01T23:00:00","EffectiveUntilDate":"2024-01-01T23:00:00","ExpiryDateTime":"","SaleStage":"Referral","CreatedFrom":"Cancellation","IsProfessions":false,"IsSme":false,"IsWholesaleSite":false,"IsDirectSite":false,"WasReferred":false,"IsDetailChange":false,"IsMTA":false,"IsRenewal":false,"QuoteStartedByAgentGroupName":"","QuoteStartedBySalesPersonName":"","SalespersonEmail":"","SalespersonName":"","AgentGroupEmail":"","AgentGroupName":"","IsBrokerAgent":false,"IsKingsbridgeAgent":false,"ProfessionalIndemnityCoverLevel":1,"PublicLiabilityCoverLevel":1,"PackageIncludesPersonalAccident":"","PersonalAccidentCoverLevel":"","PersonalAccidentDeathBenefit":"","PersonalAccidentWeeklyBenefit":"","BusinessEquipmentCoverLevel":"","BusinessEquipmentLimit":"","BusinessEquipmentLimitOfCoverRequired":1,"DirectorsAndOfficersCoverLevel":"","EmployersLiabilityCover":1,"PolicyholderTitle":"Mr.","PolicyholderFirstName":"Cedric","PolicyholderLastName":"Update","PolicyholderEmail":"test123@test.com","PolicyholderPhone":"09123223453","PolicyholderDateOfBirth":"1991-01-01","PolicyholderAddressLine1":"1","PolicyholderCity":"London","PolicyholderCountry":"UK","PolicyholderPostcode":"STK 123","BusinessName":"SampleB","BusinessType":"","CompanyStatus":"","PrimaryBusinessActivity":"","Sector":"","HasSecondaryActivity":false,"Turnover":"","NumberOfFeeEarningEmployees":1,"PriceReductionType":"","DiscountAmount":1,"PremiumAdjustment":1,"PricematchPremium":1,"TotalPremium":null,"IptAmount":1,"TotalPayable":1,"ReleaseDate":"2024-01-01","PackageBuildTag":"","PageSubmitted_Page1":"","PageSubmitted_Page2":"","PageSubmitted_Page5":"","PageSubmitted_Page8":"","PageSubmitted_QuickQuote":"","PageSubmitted_Quote":"","SiteEnvironment":"","SiteName":"","SiteType":"","Referred":false}';

        Map<String, String> headers = new Map<String, String>{ 'api-key' => '123456' };
        executePayload(payloadJSON, headers, null);
    }

    @isTest static void testIsMTAPolicyProcess() {
        Account acc = createAccount('mta@test.com');
        Contact dummyContact = new Contact(
            FirstName = 'Lukasz',
            LastName = 'Zawieja',
            Email = 'lukasz.zawieja@gmail.com'
        );
        insert dummyContact;
        PricebookEntry pbe = createPricebookEntry('Direct Professions', 1000);
        Opportunity opp = createOpportunity(acc, 'MTA123', '', 'Prospecting', Date.today(), pbe, null);
    
        // Existing policy
        Policy__c existingPolicy = createPolicy(opp, 'POLICY123', 'Live');
        
        // Prepare payload
        InstandaUtility.RequestHandler payload = new InstandaUtility.RequestHandler();
        payload.IsMTA = true;
        payload.SaleStage = 'PolicyNumberGenerated';
        payload.EffectiveUntilDate = '2026-11-26T00:00:00';
        
        Test.startTest();
        Boolean result = TransactionAPI.isMTAPolicyProcess(payload, new List<Policy__c>{existingPolicy}, opp, acc.Id);
        Test.stopTest();
        
        System.assert(result == true, 'MTA process should return true');
    }
    

    @isTest static void testIsRenewalPolicyProcess() {
        Account acc = createAccount('renewal@test.com');
        Contact dummyContact = new Contact(
            FirstName = 'Lukasz',
            LastName = 'Zawieja',
            Email = 'lukasz.zawieja@gmail.com'
        );
        insert dummyContact;
        PricebookEntry pbe = createPricebookEntry('Direct Professions', 1000);
        Opportunity opp = createOpportunity(acc, 'REN123', '', 'Prospecting', Date.today(), pbe, null);
    
        // Payload
        InstandaUtility.RequestHandler payload = new InstandaUtility.RequestHandler();
        payload.IsRenewal = true;
        payload.SaleStage = 'PaymentMade';
    
        Test.startTest();
        Boolean result = TransactionAPI.isRenewalPolicyProcess(payload, new List<Policy__c>(), opp, acc.Id);
        Test.stopTest();
    
        System.assert(result == true, 'Renewal process should return true');
    }
    

    @isTest static void testIsNewBusinessPolicyProcess() {
        Account acc = createAccount('newbusiness@test.com');
        Contact dummyContact = new Contact(
            FirstName = 'Lukasz',
            LastName = 'Zawieja',
            Email = 'lukasz.zawieja@gmail.com'
        );
        insert dummyContact;
        PricebookEntry pbe = createPricebookEntry('Direct Professions', 1000);
        Opportunity opp = createOpportunity(acc, 'NB123', '', 'Prospecting', Date.today(), pbe, null);
    
        InstandaUtility.RequestHandler payload = new InstandaUtility.RequestHandler();
        payload.CreatedFrom = 'NewBusiness';
        payload.SaleStage = 'PaymentMade';
    
        Test.startTest();
        Boolean result = TransactionAPI.isNewBusinessPolicyProcess(payload, new List<Policy__c>(), opp, acc.Id);
        Test.stopTest();
    
        System.assert(result == true, 'New Business process should return true');
    }
    

    @isTest static void testNoExistingPolicyProcess() {
        Account acc = createAccount('noexisting@test.com');
        Contact dummyContact = new Contact(
            FirstName = 'Lukasz',
            LastName = 'Zawieja',
            Email = 'lukasz.zawieja@gmail.com'
        );
        insert dummyContact;
        PricebookEntry pbe = createPricebookEntry('Direct Professions', 1000);
        Opportunity opp = createOpportunity(acc, 'NE123', '', 'Prospecting', Date.today(), pbe, null);
    
        // Quote
        Quote qt = new Quote(Name='TestQuote', OpportunityId=opp.Id, INSTANDA_Quote_ID__c='NE123', Status='Draft', ExpirationDate=Date.today().addDays(10));
        insert qt;
    
        InstandaUtility.RequestHandler payload = new InstandaUtility.RequestHandler();
        payload.SaleStage = 'PolicyNumberGenerated';
        payload.QuoteRef = 'NE123';
    
        InstandaApi__c insApi = [SELECT Id, close_date_add_days__c FROM InstandaApi__c LIMIT 1];
        TransactionAPI.ResponseHandler resp = new TransactionAPI.ResponseHandler();
        RestResponse rest = new RestResponse();
    
        Test.startTest();
        TransactionAPI.noExistingPolicyProcess(opp, acc.Id, payload, insApi, resp, rest, '');
        Test.stopTest();
    
        System.assertEquals(true, resp.success != false, 'noExistingPolicyProcess should succeed');
    }
    

    @isTest static void testCreateOfflineCase() {
        Account acc = createAccount('offline@test.com');
        PricebookEntry pbe = createPricebookEntry('Direct Professions', 1000);
        Opportunity opp = createOpportunity(acc, 'OFF123', '', 'Prospecting', Date.today(), pbe, null);
    
        InstandaUtility.RequestHandler payload = new InstandaUtility.RequestHandler();
        payload.QuoteRef = 'OFF123';
        payload.SaleCompletedBySalesPersonEmail = UserInfo.getUserEmail();
        payload.TotalPayable = 100;
    
        Test.startTest();
        TransactionAPI.createOfflineCase(payload);
        Test.stopTest();
    
        List<Case> cases = [SELECT Id, Subject FROM Case WHERE Subject LIKE '%OFF123%'];
        System.assert(cases.size() > 0, 'Offline case should be created');
    }
    
}