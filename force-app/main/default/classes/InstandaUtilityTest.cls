@IsTest
public class InstandaUtilityTest {

    @TestSetup
    static void setupTestData() {
        // Create a dummy user for assigning opportunities (if needed)
        if ([SELECT count() FROM User WHERE IsActive = true LIMIT 1] == 0) {
            Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
            User u = new User(
                FirstName='Test',
                LastName='User',
                Email='testuser@example.com',
                Username='testuser'+Math.random()+'@example.com',
                Alias='tuser',
                ProfileId=p.Id,
                TimeZoneSidKey='GMT',
                LocaleSidKey='en_US',
                EmailEncodingKey='UTF-8',
                LanguageLocaleKey='en_US'
            );
            insert u;
        }

        Auto_Number__c aut = new Auto_Number__c();
        aut.Autonumber_Partner_ID__c = 4445;
        insert aut;
        
        // Create a partner account (for Partner logic)
        Account partner = new Account(Name='Partner Account');
        insert partner;

        // Create Product2 for Policy/Opportunity
        Product2 p = new Product2(Name='IR35 Standalone Protect', isActive=true);
        insert p;

        createRequestHandler();
    }

    public static InstandaUtility.RequestHandler createRequestHandler() {
        InstandaUtility.RequestHandler payload = new InstandaUtility.RequestHandler();

        // IDs and references
        payload.QuoteRef = 'Q123';
        payload.SBJQuoteRef = 'SBJ123';
        payload.PolicyNumber = 'P123';
        payload.PolicyNumberSuffixed = 'P123-1';
        payload.ClaimRef = 'C123';
        payload.PackageName = 'IR35 Standalone Protect';
        payload.PackageCode = 'PKG123';
        payload.PackageIdentifier = 1001;

        // Dates
        payload.CreatedOn = '2026-01-01T10:00:00Z';
        payload.QuoteDate = '2026-01-01';
        payload.EffectiveFromDate = '2026-01-01T00:00:00Z';
        payload.EffectiveUntilDate = '2026-12-31T23:59:59Z';
        payload.ExpiryDateTime = '2026-12-31T23:59:59Z';
        payload.PolicyPurchaseDate = '2026-01-01T10:00:00Z';
        payload.CancellationDate = '2026-06-01T00:00:00Z';
        payload.CancellationCreatedOnDate = '2026-05-25T10:00:00Z';
        payload.PredictedRenewalDate = '2027-01-01';
        payload.CurrentRenewalDate = '2026-12-31';

        // Policy/Opportunity flags
        payload.IsProfessions = true;
        payload.IsSme = true;
        payload.IsWholesaleSite = false;
        payload.IsDirectSite = true;
        payload.WasReferred = true;
        payload.IsDetailChange = false;
        payload.IsMTA = true;
        payload.IsRenewal = true;
        payload.IsRenewalAllowedToLapse = false;
        payload.CustomerOptedOutOfRenewal = 'No';
        payload.RenewalBlocked = true;
        payload.EverMadeAnyClaim = 'Yes';

        // Sales/agent info
        payload.QuoteStartedByAgentGroupName = 'Sales Group';
        payload.QuoteStartedBySalesPersonName = 'John Doe';
        payload.SalespersonEmail = 'sales@example.com';
        payload.SaleCompletedBySalesPersonEmail = 'completed@example.com';
        payload.SalespersonName = 'Jane Smith';
        payload.AgentGroupEmail = 'agentgroup@example.com';
        payload.AgentGroupName = 'Agent Group';
        payload.IsBrokerAgent = true;
        payload.IsKingsbridgeAgent = false;

        // Cover levels & insurance info
        payload.ProfessionalIndemnityCoverLevel = 500000;
        payload.PublicLiabilityCoverLevel = 1000000;
        payload.PackageIncludesPersonalAccident = 'Yes';
        payload.PersonalAccidentCoverLevel = 'Level 1';
        payload.PersonalAccidentDeathBenefit = '50000';
        payload.PersonalAccidentWeeklyBenefit = '500';
        payload.BusinessEquipmentCoverLevel = 'Level 2';
        payload.BusinessEquipmentLimit = '10000';
        payload.BusinessEquipmentLimitOfCoverRequired = 10000;
        payload.DirectorsAndOfficersCoverLevel = 'Standard';
        payload.EmployersLiabilityCover = 1000000;
        payload.AcceptHealthcareExclusion = 'Yes';
        payload.AcceptLegalServicesExclusion = 'Yes';
        payload.IR35CoverLevel = 'Level 1';
        payload.SafetyCriticalWork = 'Yes';

        // Policyholder info
        payload.PolicyholderTitle = 'Mr';
        payload.PolicyholderFirstName = 'John';
        payload.PolicyholderLastName = 'Doe';
        payload.PolicyholderEmail = 'john.doe@example.com';
        payload.PolicyholderPhone = '0123456789';
        payload.PolicyholderAlternativePhone = '0987654321';
        payload.PolicyholderDateOfBirth = '1980-01-01T00:00:00Z';
        payload.PolicyholderAddressLine1 = '123 Main Street';
        payload.PolicyholderCity = 'London';
        payload.PolicyholderCountry = 'UK';
        payload.PolicyholderPostcode = 'SW1A 1AA';
        payload.BusinessName = 'Doe Enterprises';
        payload.BusinessType = 'Sole Trader';
        payload.CompanyStatus = 'Active';
        payload.PrimaryBusinessActivity = 'IT Services';
        payload.Sector = 'Technology';
        payload.HasSecondaryActivity = true;
        payload.Turnover = '500000';
        payload.PriceReductionType = 'Seasonal';
        payload.DiscountAmount = 100;
        payload.PremiumAdjustment = 50;
        payload.PricematchPremium = 500;
        payload.TotalPremium = 1000;
        payload.IptAmount = 50;
        payload.VatAmount = 20;
        payload.PaymentType = 'Card';
        payload.PaymentTypeName = 'Monthly';
        payload.TotalPayable = 1070;
        payload.InstalmentAmount = 107;

        // Referral info
        payload.RafLink = 'https://raf.example.com';
        payload.RafReferredByName = 'Alice Referrer';
        payload.RafReferredByEmail = 'alice.ref@example.com';
        payload.Referred = true;
        payload.UnlistedReferralCompany = 'Ref Co';

        // Additional info
        payload.ERN = 'ERN123';
        payload.utm_source = 'google';
        payload.utm_term = 'insurance';
        payload.utm_medium = 'cpc';
        payload.utm_content = 'ad1';
        payload.utm_campaign = 'campaign1';
        payload.CurrentlyHaveBusinessInsurance = 'Yes';
        payload.InsuredByAlready = 'Other Insurer';

        // Employee numbers
        payload.NumberOfFeeEarningEmployees = 5;
        payload.NumberOfClericalEmployees = 2;
        payload.NumberOfFamilyClerical = 1;
        payload.NumberOfNonFamilyClerical = 1;

        // Secondary business activities
        payload.SmeBusinessActivity_2 = 'Consulting';
        payload.SmeBusinessActivity_3 = 'Support';
        payload.SmeBusinessActivity_4 = 'Maintenance';
        payload.SmeBusinessActivity_5 = 'Training';

        // Work types
        payload.WorkAtHeight = 'Yes';
        payload.ManualWork = 'Yes';
        payload.WorkOffshore = 'Yes';
        payload.RicsMember = 'Yes';

        // USA/Canada work
        payload.UsaWorkOrContract = 'Yes';
        payload.UsaContract = 'Yes';
        payload.UsaPhysical = 'Yes';
        payload.UsaOver30Days = 'Yes';

        // Cancellation / special cases
        payload.CancellationConfirmedDate = '2026-06-01T00:00:00Z';
        payload.CancellationEffectiveFromDate = '2026-06-01T00:00:00Z';
        payload.TopLevelCancellationReason = 'Client request';
        payload.EverDeclinedOrSpecialTerms = 'Yes';
        payload.EverDeclinedOrSpecialTermsDetails = 'Special terms applied';
        payload.NonMotoringCriminalOffences = 'None';
        payload.HeatOrHighVoltageWork = 'Yes';
        payload.AcceptNuclearExclusion = 'Yes';
        payload.AddCyberLiability = 'Yes';
        payload.HasLegalExpenses = 'Yes';
        payload.AcceptAviationExclusion = 'Yes';
        payload.AcceptArchitectureExclusion = 'Yes';
        payload.BankruptOrAdministration = 'No';
        payload.EverBankruptOrAdministration = 'No';

        // IR35 / Premium info
        payload.IR35StatusToolFee = 200;
        payload.MtaHasPremiumRefund = true;
        payload.MTA_TotalPayable = 100;

        // Counts
        payload.RenewalCount = '1';
        payload.MtaCount = '0';

        // Where heard
        payload.WhereHeard = 'My friend';
        payload.WhereHeardFriendName = 'Bob Friend';
        payload.WhereHeardFriendEmail = 'bob.friend@example.com';
        payload.WhereHeardEmployerClientCompany = 'Employer Inc';
        payload.WhereHeardEmployerClientPerson = 'Employer Person';
        payload.WhereHeardPartnerPerson = 'Partner Person';
        payload.PartnerCompanyPerson = 'Partner Company Person';
        payload.PartnerId = null;

        return payload;
    }

    @IsTest
    static void testCollectAccount() {
        InstandaUtility.RequestHandler payload = new InstandaUtility.RequestHandler();
        payload.PolicyNumber = 'POL123';
        payload.QuoteRef = 'Q123';
        payload.PolicyholderTitle = 'Mr';
        payload.PolicyholderFirstName = 'John';
        payload.PolicyholderLastName = 'Doe';
        payload.PolicyholderDateOfBirth = '1990-01-01T00:00:00Z';
        payload.PolicyholderEmail = 'john.doe@example.com';
        payload.PolicyholderPhone = '123456789';
        payload.CustomerOptedOutOfRenewal = 'Yes';
        
        Account acc = InstandaUtility.collectAccount(payload);
        
        System.assertEquals('POL123', acc.INSTANDA_Policy_ID__c);
        System.assertEquals('Q123', acc.INSTANDA_Quote_ID__c);
        System.assertEquals(Date.newInstance(1990,1,1), acc.PersonBirthDate);
        System.assertEquals(false, acc.Auto_Renew__c); // opted out
    }

    @IsTest
    static void testCollectLead() {
        InstandaUtility.RequestHandler payload = new InstandaUtility.RequestHandler();
        payload.QuoteRef = 'Q123';
        payload.SBJQuoteRef = 'SBJ123';
        payload.PolicyholderFirstName = 'Jane';
        payload.PolicyholderLastName = 'Doe';
        payload.PolicyholderDateOfBirth = '1995-05-15T00:00:00Z';
        payload.PolicyholderEmail = 'jane.doe@example.com';
        
        Lead ld = InstandaUtility.collectLead(payload);
        System.assertEquals('Q123', ld.INSTANDA_Quote_ID__c);
        System.assertEquals(Date.newInstance(1995,5,15), ld.Birthdate__c);
    }

    @IsTest
    static void testCollectOpportunity() {
        InstandaUtility.RequestHandler payload = new InstandaUtility.RequestHandler();
        payload.QuoteRef = 'Q456';
        payload.PackageName = 'IR35 Standalone Protect';
        payload.TotalPremium = 1000;
        payload.DiscountAmount = 50;
        payload.PredictedRenewalDate = '2026-01-01';
        payload.SalespersonName = 'Sales Person';
        payload.IR35StatusToolFee = 25;
        
        Opportunity opp = InstandaUtility.collectOpp(payload);
        System.assertEquals('Q456', opp.INSTANDA_Quote_ID__c);
        System.assertEquals(1000, opp.Premium__c); // 1000 + 25
        System.assertEquals('Sales Person', opp.First_Quoted_By__c);
        System.assertEquals(Date.newInstance(2026,1,1), opp.CloseDate);
    }

    @IsTest
    static void testCollectPolicy() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        User u = [SELECT Id FROM User LIMIT 1];
        
        InstandaUtility.RequestHandler payload = new InstandaUtility.RequestHandler();
        payload.PolicyNumber = 'POL789';
        payload.QuoteRef = 'Q789';
        payload.TotalPremium = 500;
        payload.TotalPayable = 550;
        payload.PackageName = 'IR35 Standalone Protect';
        payload.PolicyPurchaseDate = '2026-01-01T00:00:00Z';
        payload.PaymentType = 'Credit';
        payload.PaymentTypeName = 'Card';
        payload.EffectiveFromDate = '2026-01-01T00:00:00Z';
        
        Policy__c pol = InstandaUtility.collectPolicy(payload, acc.Id, u.Id);
        System.assertEquals(acc.Id, pol.Customer__c);
        System.assertEquals(u.Id, pol.OwnerId);
        System.assertEquals(550, pol.Premium_Value__c);
        System.assertEquals('Credit - Card', pol.Payment_Method__c);
        System.assertEquals(Date.newInstance(2026,1,1), pol.Inception_Date_Time__c.date());
    }

    @IsTest
    static void testDetermineLeadSource() {
        System.assertEquals('RAF', InstandaUtility.determineLeadSource('My friend'));
        System.assertEquals('Partner', InstandaUtility.determineLeadSource('Accountancy/recruitment company/professional body'));
        System.assertEquals('Direct', InstandaUtility.determineLeadSource('Search engine'));
        System.assertEquals(null, InstandaUtility.determineLeadSource('Unknown Source'));
    }

    @IsTest
    static void testIsValid() {
        System.assertEquals(false, InstandaUtility.isValid(''));
        System.assertEquals(true, InstandaUtility.isValid('Hello'));
        System.assertEquals(false, InstandaUtility.isValid(null));
        System.assertEquals(true, InstandaUtility.isValid(123));
    }

    @IsTest
    static void testConvertToUTCDateTime() {
        Datetime dt = InstandaUtility.convertToUTCDateTime('2026-01-01T12:30:15Z');
        System.assertEquals(2026, dt.yearGMT());
        System.assertEquals(1, dt.monthGMT());
        System.assertEquals(1, dt.dayGMT());
        System.assertEquals(12, dt.hourGMT());
        System.assertEquals(30, dt.minuteGMT());
        System.assertEquals(15, dt.secondGMT());
    }
}