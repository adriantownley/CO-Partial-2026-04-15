@RestResource(urlMapping='/upsertLeads/*')
global class UpsertLeadsAPI {
    @HttpPost
    global static void processRecords(){
        ResponseHandler resp = new ResponseHandler();
        RestResponse rest = RestContext.response;
        try{
            resp.success = true;

            Map<String, String> reqHeadersMap = RestContext.request.headers;
            if(reqHeadersMap.containsKey('api-key')){
                InstandaApi__c insApi = InstandaApi__c.getOrgDefaults();

                if(insApi.api_key__c == reqHeadersMap.get('api-key')){
                    String reqBody = RestContext.request.requestBody.toString();
                    RequestHandler payload = (RequestHandler)JSON.deserialize(reqBody, RequestHandler.class);


                }else{
                    resp.success = false;
                    resp.errorMessage = 'Unauthorized';
                    rest.statusCode = 401;
                }
            }else{
                resp.success = false;
                resp.errorMessage = 'Forbidden';
                rest.statusCode = 403;
            }
        }catch(Exception ex){
            resp.success = false;
            resp.errorMessage = ex.getMessage() + ' line ' + ex.getLineNumber();
            rest.statusCode = 500;
        }

        if(!Test.IsRunningTest()){
            rest.responseBody = Blob.valueOf(JSON.serialize(resp, true));
        }
    }

    public class ResponseHandler{
        public Boolean success;
        public String errorMessage;
    }

    public class RequestHandler{
        public String QuoteRef;
        public String SBJQuoteRef;
        public String PolicyNumber;
        public String PackageName;
        public String PackageCode;
        public Integer PackageIdentifier;
        public String CreatedOn;
        public String QuoteDate;
        public String EffectiveFromDate;
        public String EffectiveUntilDate;
        public String ExpiryDateTime;
        public String SaleStage;
        public String CreatedFrom;
        public Boolean IsProfessions;
        public Boolean IsSme;
        public Boolean IsWholesaleSite;
        public Boolean IsDirectSite;
        public Boolean WasReferred;
        public Boolean IsDetailChange;
        public Boolean IsMTA;
        public Boolean IsRenewal;
        public String QuoteStartedByAgentGroupName;
        public String QuoteStartedBySalesPersonName;
        public String SalespersonEmail;
        public String SalespersonName;
        public String AgentGroupEmail;
        public String AgentGroupName;
        public Boolean IsBrokerAgent;
        public Boolean IsKingsbridgeAgent;
        public Decimal ProfessionalIndemnityCoverLevel;
        public Decimal PublicLiabilityCoverLevel;
        public String PackageIncludesPersonalAccident;
        public String PersonalAccidentCoverLevel;
        public String PersonalAccidentDeathBenefit;
        public String PersonalAccidentWeeklyBenefit;
        public String BusinessEquipmentCoverLevel;
        public String BusinessEquipmentLimit;
        public Decimal BusinessEquipmentLimitOfCoverRequired;
        public String DirectorsAndOfficersCoverLevel;
        public Decimal EmployersLiabilityCover;
        public String PolicyholderTitle;
        public String PolicyholderFirstName;
        public String PolicyholderLastName;
        public String PolicyholderEmail;
        public String PolicyholderPhone;
        public String PolicyholderDateOfBirth;
        public String PolicyholderAddressLine1;
        public String PolicyholderCity;
        public String PolicyholderCountry;
        public String PolicyholderPostcode;
        public String BusinessName;
        public String BusinessType;
        public String CompanyStatus;
        public String PrimaryBusinessActivity;
        public String Sector;
        public Boolean HasSecondaryActivity;
        public String Turnover;
        public Decimal NumberOfFeeEarningEmployees;
        public String PriceReductionType;
        public Decimal DiscountAmount;
        public Decimal PremiumAdjustment;
        public Decimal PricematchPremium;
        public Decimal TotalPremium;
        public Decimal IptAmount;
        public Decimal TotalPayable;
        public String ReleaseDate;
        public String PackageBuildTag;
        public String PageSubmitted_Page1;
        public String PageSubmitted_Page2;
        public String PageSubmitted_Page5;
        public String PageSubmitted_Page8;
        public String PageSubmitted_QuickQuote;
        public String PageSubmitted_Quote;
        public String SiteEnvironment;
        public String SiteName;
        public String SiteType;
    }
}