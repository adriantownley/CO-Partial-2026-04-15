@RestResource(urlMapping='/submitTransaction/*')
global class TransactionAPI {
    @HttpPost
    global static void processRecords(){
        ResponseHandler resp = new ResponseHandler();
        RestResponse rest = RestContext.response;   

        String reqBody = RestContext.request.requestBody.toString();
        System.debug('***reqBody= ' + reqBody);

        Savepoint sp = Database.setSavepoint();
        try{
            resp.success = true;
            Map<String, String> reqParamsMap = RestContext.request.params;
            
            if(reqParamsMap.containsKey('action')){
                if(reqParamsMap.get('action') == 'cancellation'){
                    InstandaUtility.RequestHandler payload = (InstandaUtility.RequestHandler)JSON.deserialize(reqBody, InstandaUtility.RequestHandler.class);
                    Boolean isNotWholesaleSite = (!isValid(payload.IsWholesaleSite)) || (isValid(payload.IsWholesaleSite) && !payload.IsWholesaleSite);
                    if(isNotWholesaleSite){
                        if(isValid(payload.SaleStage) && isValid(payload.PolicyNumber)){
                            if(payload.SaleStage == 'CancelScheduled' || payload.SaleStage == 'Cancelled'){

                                List<Policy__c> policies = [SELECT Id, From_Opportunity__c FROM Policy__c WHERE INSTANDA_Policy_ID__c=: payload.PolicyNumber LIMIT 1];

                                if(!policies.isEmpty()){
                                    Policy__c pol = policies[0];
                                    pol.Status__c = 'Cancelled';
                                    if(isValid(payload.CancellationConfirmedDate)){
                                        pol.Cancellation_Date_Requested__c = InstandaUtility.convertToUTCDateTime(payload.CancellationConfirmedDate);
                                    }
                                    if(isValid(payload.CancellationEffectiveFromDate)){
                                        pol.Cancellation_Date_Effective__c = InstandaUtility.convertToUTCDateTime(payload.CancellationEffectiveFromDate);
                                    }
                                    pol.Cancellation_Reason__c = payload.TopLevelCancellationReason;
                                    update pol;
                                }
                            }
                        }
                    }
                }
            }else{
                Map<String, String> reqHeadersMap = RestContext.request.headers;
                if(reqHeadersMap.containsKey('api-key')){
                    InstandaApi__c insApi = InstandaApi__c.getOrgDefaults();
    
                    if(insApi.api_key__c == reqHeadersMap.get('api-key')){
                        InstandaUtility.RequestHandler payload = (InstandaUtility.RequestHandler)JSON.deserialize(reqBody, InstandaUtility.RequestHandler.class);
                        system.debug('***payload = ' + payload);

                        Boolean isNotWholesaleSite = (!isValid(payload.IsWholesaleSite)) || (isValid(payload.IsWholesaleSite) && !payload.IsWholesaleSite);
                        
                        if(isNotWholesaleSite){
                            Id accId = null;
                            Id oppId = null;
                            Id conId = null;
                            Id pricebookId = null;
                            Opportunity parentOpp = new Opportunity();
                            Id underwritingRecordTypeId = InstandaUtility.getRecordTypeIdbyName('Case', 'Underwriting');
        
                            List<Pricebook2> pricebooks = [SELECT Id FROM Pricebook2 WHERE isStandard = true LIMIT 1];
                            if(!pricebooks.isEmpty()){
                                pricebookId = pricebooks[0].Id;
                            }
        
                            if(isValid(payload.PolicyholderEmail)){
                                List<Account> accounts = [SELECT Id, PersonContactId FROM Account WHERE PersonEmail =: payload.PolicyholderEmail LIMIT 1];
                                if(!accounts.isEmpty()){
                                    accId = accounts[0].Id;
                                    conId = accounts[0].PersonContactId;
                                }
                            }
        
                            if(isValid(payload.QuoteRef)){
                                List<Opportunity> opps = [SELECT Id, Name, AccountId, SBJ_Quote_ID__c, OwnerId, RecordTypeId, RecordType.Name, SyncedQuoteId, Referred__c,
                                                            (SELECT Id FROM Quotes), 
                                                            (SELECT Id FROM Cases__r WHERE isClosed = false AND RecordTypeId =: underwritingRecordTypeId) 
                                                            FROM Opportunity 
                                                            WHERE INSTANDA_Quote_ID__c =: payload.QuoteRef 
                                                            AND isClosed = false 
                                                            ORDER BY CreatedDate DESC
                                                            LIMIT 1];
                                if(!opps.isEmpty()){
                                    parentOpp = opps[0];
                                    oppId = opps[0].Id;
                                }else{
                                    List<Opportunity> opps2 = [SELECT Id, Name, AccountId, SBJ_Quote_ID__c, OwnerId, RecordTypeId, RecordType.Name, SyncedQuoteId, Referred__c,
                                                            (SELECT Id FROM Quotes), 
                                                            (SELECT Id FROM Cases__r WHERE isClosed = false AND RecordTypeId =: underwritingRecordTypeId) 
                                                            FROM Opportunity 
                                                            WHERE INSTANDA_Quote_ID__c =: payload.QuoteRef
                                                            ORDER BY CreatedDate DESC
                                                            LIMIT 1];
                                    if(!opps2.isEmpty()){
                                        parentOpp = opps2[0];
                                        oppId = opps2[0].Id;
                                    }
                                }
                            }

                            accId = (accId != null) ? accId : parentOpp.AccountId;
                            
                            //Opportunity Referred START
                            if(oppId != null){
                                opportunityReferred(oppId, accId, conId, parentOpp, payload, underwritingRecordTypeId);
                            }
                            //Opportunity Referred END
                            //needs to add a validation - checking if the opporunity is empty or not


                            //POLICY START
                            if(isValid(payload.PolicyNumber)){
                                system.debug('***POLICY NUMBER VALID - accId = ' + accId);
                                if(accId != null){
                                    Account acc = InstandaUtility.collectAccount(payload);
                                    acc.Id = accId;
                                    update acc;

                                    List<Policy__c> policies = [SELECT Id, From_Opportunity__c, Customer__c, Expiry_Date_time__c, Status__c
                                                                FROM Policy__c WHERE INSTANDA_Policy_ID__c=: payload.PolicyNumber ORDER BY CreatedDate DESC LIMIT 1];

                                    if(!policies.isEmpty()){
                                        Boolean insertPolicyMTA = false;
                                        Boolean insertPolicyRenewal = false;
                                        Boolean insertNewBusinessPolicy = false;

                                        //MTA
                                        insertPolicyMTA = isMTAPolicyProcess(payload, policies, parentOpp, accId);
                                        system.debug('***insertPolicyMTA = ' + insertPolicyMTA);
                                        
                                        //RENEWAL
                                        insertPolicyRenewal = isRenewalPolicyProcess(payload, policies, parentOpp, accId);
                                        system.debug('***insertPolicyRenewal = ' + insertPolicyRenewal);

                                        //NEWBUSINESS
                                        insertNewBusinessPolicy = isNewBusinessPolicyProcess(payload, policies, parentOpp, accId);
                                        system.debug('***insertNewBusinessPolicy = ' + insertNewBusinessPolicy);
                                        
                                    }else{
                                        //NO EXISTING POLICY
                                        system.debug('***No Existing Policy');
                                        noExistingPolicyProcess(parentOpp, accId, payload, insApi, resp, rest, reqBody);
                                    }
                                }else{
                                    resp.success = false;
                                    resp.errorMessage = 'No existing policy holder with email - ' + payload.PolicyholderEmail;
                                    rest.statusCode = 503;
            
                                    notifyUsers(null, resp.errorMessage, reqBody);
                                }
                            }else{
                                //consolidated trigger 1,2, and 3
                                //NO VALID POLICY NUMBER
                                system.debug('***POLICY NUMBER NOT VALID');

                                Id processOppId = null;
                                Boolean createOpp = false;
                                Boolean hasOptedOut = isValid(payload.CustomerOptedOutOfRenewal) ? ((payload.CustomerOptedOutOfRenewal == 'Yes') ? true : false) : false;
                                
                                Id emailUserId = null;
                                String emailToMatch = '';
                                if(payload.SiteType == 'Agent'){
                                    if(isValid(payload.SalespersonEmail)){
                                        emailToMatch = payload.SalespersonEmail;
                                    }
                                }else{
                                    emailToMatch = Label.API_User_Email;
                                }

                                if(!String.isBlank(emailToMatch)){
                                    List<User> users = [SELECT Id FROM User WHERE Email =: emailToMatch LIMIT 1];
                                    if(!users.isEmpty()){
                                        emailUserId = users[0].Id;
                                    }
                                }
                                //first check if there's an existing opportunity
                                Boolean isSBJAvailable = isValid(payload.SBJQuoteRef);
                                if(isSBJAvailable){
                                    List<Opportunity> sbjOpps = [SELECT Id, RecordType.Name
                                                                    FROM Opportunity 
                                                                    WHERE (SBJ_Quote_ID__c =: payload.SBJQuoteRef 
                                                                    OR INSTANDA_Quote_ID__c =: payload.QuoteRef)
                                                                    AND isClosed = false 
                                                                    LIMIT 1];
                                    if(!sbjOpps.isEmpty()){
                                        Opportunity opp = sbjOpps[0];
                                        processOppId = (hasOptedOut) ? ((opp.RecordType.Name == 'Auto-Renewal Opportunity') ? opp.Id : null) : opp.Id;
                                    }
                                }else{
                                    List<Opportunity> opps = [SELECT Id, RecordType.Name
                                                                FROM Opportunity 
                                                                WHERE INSTANDA_Quote_ID__c =: payload.QuoteRef 
                                                                AND isClosed = false 
                                                                LIMIT 1];
                                    if(!opps.isEmpty()){
                                        Opportunity opp = opps[0];
                                        processOppId = (hasOptedOut) ? ((opp.RecordType.Name == 'Auto-Renewal Opportunity') ? opp.Id : null) : opp.Id;
                                    }
                                }
 
                                //if no opportunity is found using the QuoteRef/SBJ QuoteRef matching
                                //find an closed lost opportunity tied to the parent account with the same product as supplied in payload
                                if(processOppId == null && accId != null && String.isNotBlank(payload.PackageName)){
                                    //this logic should be applicable to both IR35 and non-IR35
                                    List<Opportunity> closedLostOpps = [SELECT Id, RecordType.Name, Closed_Lost_Date__c
                                                                            FROM Opportunity
                                                                            WHERE AccountId =: accId
                                                                            AND StageName = 'Closed Lost'
                                                                            AND Closed_Lost_Date__c > :Date.today().addDays(-30)
                                                                            AND Product_Type__c INCLUDES (:payload.PackageName)
                                                                            ORDER BY CreatedDate DESC 
                                                                            LIMIT 1];
                                    if(!closedLostOpps.isEmpty()){
                                        Opportunity opp = closedLostOpps[0];
                                        processOppId = (hasOptedOut) ? ((opp.RecordType.Name == 'Auto-Renewal Opportunity') ? opp.Id : null) : opp.Id;
                                    }

                                    if(processOppId == null){
                                        List<Opportunity> openOpps = [SELECT Id, RecordType.Name
                                                                            FROM Opportunity
                                                                            WHERE AccountId =: accId
                                                                            AND isClosed = false 
                                                                            AND Product_Type__c INCLUDES (:payload.PackageName)
                                                                            ORDER BY CreatedDate DESC 
                                                                            LIMIT 1];

                                        if(!openOpps.isEmpty()){
                                            Opportunity opp = openOpps[0];
                                            processOppId = (hasOptedOut) ? ((opp.RecordType.Name == 'Auto-Renewal Opportunity') ? opp.Id : null) : opp.Id;
                                        }
                                    }
                                }

                                //if an opportunity is found after the above checks, update the found opportunity
                                Boolean isNotSME = (!isValid(payload.isSME)) || (isValid(payload.isSme) && !payload.isSme);
                                if(processOppId != null){
                                    List<Opportunity> processOpps = [SELECT Id, Name, INSTANDA_Quote_ID__c, SBJ_Quote_ID__c, OwnerId, RecordTypeId, RecordType.Name, LeadSource, Partner__c,
                                                                        (SELECT Id FROM Quotes) 
                                                                        FROM Opportunity 
                                                                        WHERE Id =: processOppId];
                                    if(!processOpps.isEmpty()){
                                        Opportunity processOpp = processOpps[0];

                                        Opportunity opp = InstandaUtility.collectOpp(payload);
                                        opp.Id = processOppId;
                                        opp.StageName = 'Qualification';
                                        if((processOpp.RecordType.Name == 'Manual Renewal Opportunity' && processOpp.Quotes.size() > 0) || processOpp.RecordType.Name == 'New Business Opportunity'){
                                            String opportunityName = '';
                                            if(!isNotSME){
                                                opportunityName = 'SME - ';
                                            }

                                            String appendName = (payload.CreatedFrom == 'MTA') ? 'Mid-Term Opportunity' : processOpp.RecordType.Name;
                                            opportunityName += payload.PackageName + ' - ' + payload.QuoteRef + ' - ' + appendName;
                                            opp.Name = (opportunityName.length() > 120) ? opportunityName.left(120) : opportunityName;
                                        }
                                        if(isSBJAvailable){
                                            opp.SBJ_Quote_ID__c = payload.SBJQuoteRef;
                                        }
                                        if(hasOptedOut){
                                            opp.RecordTypeId = InstandaUtility.getRecordTypeIdbyName('Opportunity', 'Manual Renewal Opportunity');
                                        }
                                        update opp;

                                        Boolean createSource = false;
                                        Boolean isPreviousOppSBJ = (processOpp.Name.contains('Single Buying Journey'));
                                        if(isPreviousOppSBJ){
                                            List<Quote> quotes = [SELECT Id FROM Quote WHERE INSTANDA_Quote_ID__c =: processOpp.INSTANDA_Quote_ID__c AND OpportunityId =: processOppId LIMIT 1];
                                            if(!quotes.isEmpty()){
                                                createSource = true;

                                                Id quoteId = quotes[0].Id;

                                                Quote qt = InstandaUtility.collectQuote(payload);
                                                qt.Id = quoteId;
                                                update qt;
                                            }

                                            List<Lead> dupeLeads = [SELECT Id FROM Lead WHERE Email =: payload.PolicyholderEmail AND Product_Type__c =: payload.PackageName AND isConverted = false];
                                            if(!dupeLeads.isEmpty()){
                                                for (Lead dupeLd : dupeLeads) {
                                                    Lead_Delete_Request__e deleteRequest = new Lead_Delete_Request__e(
                                                        LeadId__c = dupeLd.Id,
                                                        OpportunityId__c = processOppId
                                                    );

                                                    Database.SaveResult result = EventBus.publish(deleteRequest);
                                                }
                                            }
                                        }else{
                                            List<Quote> quotes = [SELECT Id FROM Quote WHERE INSTANDA_Quote_ID__c =: payload.QuoteRef AND OpportunityId =: processOppId LIMIT 1];
                                            if(!quotes.isEmpty()){
                                                Id quoteId = quotes[0].Id;

                                                Quote qt = InstandaUtility.collectQuote(payload);
                                                if(payload.PackageName.contains('IR35')){
                                                    qt.Status = 'Quote Provided';
                                                }
                                                qt.Id = quoteId;
                                                update qt;
                                            }else{
                                                createSource = true;

                                                Quote qt = InstandaUtility.collectQuote(payload);
                                                qt.OpportunityId = processOppId;
                                                qt.Name = opp.Name + processOpp.Quotes.size() + 1;
                                                if(emailUserId != null){
                                                    qt.OwnerId = emailUserId;
                                                }
                                                insert qt;
                                            }
                                        }

                                        List<Opportunity> requeryOpps = [SELECT Id, Name, INSTANDA_Quote_ID__c, SBJ_Quote_ID__c, OwnerId, RecordTypeId, RecordType.Name, LeadSource, Partner__c
                                                                            FROM Opportunity 
                                                                            WHERE Id =: processOppId];
                                        if(!requeryOpps.isEmpty()){
                                            Opportunity reqOpp = requeryOpps[0];
                                            if(createSource && payload.PackageName != 'Single Buying Journey'){
                                                Attribution__c att = InstandaUtility.collectAttribution(payload);
                                                att.Opportunity__c = processOppId;
                                                att.Name = reqOpp.Name;
                                                att.Lead_Source__c = reqOpp.LeadSource;
                                                att.Partner__c = reqOpp.Partner__c;
                                                insert att;
                                            }else{
                                                List<Attribution__c> sources = [SELECT Id FROM Attribution__c WHERE Name =: reqOpp.Name ORDER BY CreatedDate DESC LIMIT 1];
                                                if(!sources.isEmpty()){
                                                    Attribution__c att = InstandaUtility.collectAttribution(payload);
                                                    att.Id = sources[0].Id;
                                                    att.Opportunity__c = processOppId;
                                                    att.Name = reqOpp.Name;
                                                    att.Lead_Source__c = reqOpp.LeadSource;
                                                    att.Partner__c = reqOpp.Partner__c;
                                                    update att;
                                                }
                                            }
                                        }
                                    }
                                }else{
                                    //in this line, we are sure that we are NOT creating a duplicate opportunity
                                    if(accId != null){
                                        createOpp = true;
                                        Opportunity opp = InstandaUtility.collectOpp(payload);
                                        opp.CloseDate = Date.today().addDays(Integer.valueOf(insApi.close_date_add_days__c));
                                        opp.Pricebook2Id = pricebookId;
                                        opp.AccountId = accId;
                                        opp.ContactId = conId;
                                        if(isValid(payload.SBJQuoteRef)){
                                            opp.SBJ_Quote_ID__c = payload.SBJQuoteRef;
                                        }
                                        
                                        if(hasOptedOut){
                                            Integer lastAssignedIndex = (insApi.last_assigned_index__c != null) ? Integer.valueOf(insApi.last_assigned_index__c) : -1;
                                            InstandaUtility.GetOwnerWrapper ownerWrap = InstandaUtility.getOwnerId(lastAssignedIndex);
                                            insApi.Last_Assigned_Index__c = String.valueOf(ownerWrap.lastAssignedIndex);
                                            update insApi;

                                            opp.OwnerId = ownerWrap.ownerId;
                                        }else{
                                            InstandaUtility.GetMembersWrapper wrap = InstandaUtility.getMembers(false);
                                            if(!wrap.memberIdList.isEmpty()){
                                                opp.OwnerId = wrap.memberIdList[0];
                                            }else{
                                                opp.OwnerId = wrap.failBackUserId;
                                            }
                                        }

                                        String recordTypeName = (hasOptedOut) ? 'Manual Renewal Opportunity' : (payload.CreatedFrom == 'NewBusiness') ? 'New Business Opportunity' : 'Auto-Renewal Opportunity';
                                        opp.RecordTypeId = InstandaUtility.getRecordTypeIdbyName('Opportunity', recordTypeName);
                                        
                                        String opportunityName = '';
                                        if(!isNotSME){
                                            opportunityName = 'SME - ';
                                        }
                                        
                                        String appendName = (payload.CreatedFrom == 'MTA') ? 'Mid-Term Opportunity' : recordTypeName;
                                        opportunityName += payload.PackageName + ' - ' + payload.QuoteRef + ' - ' + appendName;
                                        opp.Name = (opportunityName.length() > 120) ? opportunityName.left(120) : opportunityName;
                                        opp.LeadSource = 'API';
                                        insert opp;

                                        processOppId = opp.Id;
                                    }else{
                                        Id leadId = null;
                                        String leadSource = '';
                                        Lead auxLead = new Lead();

                                        List<Lead> unqualifiedLeads = [SELECT Id, Partner__c, Unqualified_Date__c, Product_Type__c, LeadSource
                                                                FROM Lead 
                                                                WHERE Email =: payload.PolicyholderEmail
                                                                AND Status = 'Unqualified'
                                                                AND Unqualified_Date__c > :Date.today().addDays(-30)
                                                                AND Product_Type__c INCLUDES (:payload.PackageName)
                                                                AND isConverted = false
                                                                ORDER BY CreatedDate DESC 
                                                                LIMIT 1];

                                        if(!unqualifiedLeads.isEmpty()){
                                            leadId = unqualifiedLeads[0].Id;
                                            leadSource = unqualifiedLeads[0].LeadSource;
                                            auxLead = unqualifiedLeads[0];
                                        }

                                        if(leadId == null){
                                            system.debug('***IN CHECK');
                                            List<Lead> openLeads = [SELECT Id, Partner__c, Unqualified_Date__c, Product_Type__c, LeadSource
                                                                FROM Lead 
                                                                WHERE Email =: payload.PolicyholderEmail
                                                                AND Status != 'Unqualified'
                                                                AND isConverted = false
                                                                ORDER BY CreatedDate DESC 
                                                                LIMIT 1];

                                            if(!openLeads.isEmpty()){
                                                if (openLeads[0].Product_Type__c != null) {
                                                    Set<String> productTypes = new Set<String>();
                                                    productTypes.addAll(openLeads[0].Product_Type__c.split(';'));

                                                    if(productTypes.contains('Admiral Trades') || productTypes.contains('FUL Trades')){
                                                        productTypes.add('Single Buying Journey');
                                                    }
                                                
                                                    if (productTypes.contains(payload.PackageName)) {
                                                        leadId = openLeads[0].Id;
                                                        leadSource = openLeads[0].LeadSource;
                                                        auxLead = openLeads[0];
                                                    }
                                                }
                                            }
                                        }

                                        if(leadId != null){
                                            Lead ld = InstandaUtility.collectUpdateLead(payload);
                                            ld.Id = leadId;
                                            ld.Status = 'Working';
                                            ld.Source__c = isValid(payload.WhereHeard) ? InstandaUtility.determineLeadSource(payload.WhereHeard) : 'Direct';
                                            ld.Attribution__c = payload.WhereHeard;
                                            if(isValid(payload.PartnerCompanyOther)){
                                                ld.Other_Partner__c = payload.PartnerCompanyOther;

                                                if(auxLead.Partner__c == null){
                                                    List<Account> accounts = [SELECT Id FROM Account WHERE Name =: payload.PartnerCompanyOther LIMIT 1];
                                                    if(!accounts.isEmpty()){
                                                        ld.Partner__c = accounts[0].Id;
                                                    }
                                                }
                                            }
                                            update ld;
                                        }else{
                                            Lead ld = InstandaUtility.collectLead(payload);
                                            ld.RecordTypeId = InstandaUtility.getRecordTypeIdbyName('Lead', 'Customer Lead');
                                            ld.LeadSource = 'API';
                                            ld.Source__c = isValid(payload.WhereHeard) ? InstandaUtility.determineLeadSource(payload.WhereHeard) : 'Direct';
                                            ld.Attribution__c = payload.WhereHeard;
                                            if(isValid(payload.PartnerCompanyOther)){
                                                ld.Other_Partner__c = payload.PartnerCompanyOther;
                                                
                                                List<Account> accounts = [SELECT Id FROM Account WHERE Name =: payload.PartnerCompanyOther LIMIT 1];
                                                if(!accounts.isEmpty()){
                                                    ld.Partner__c = accounts[0].Id;
                                                }
                                            }
                                            insert ld;
            
                                            leadId = ld.Id;
                                            leadSource = 'API';
                                        }
    
                                        if(leadId != null){
                                            List<Lead> existLeads = [SELECT Id, OwnerId FROM Lead WHERE Id =: leadId];
                                            if(!existLeads.isEmpty()){
                                                Lead existLead = existLeads[0];
                                                if(existLead.OwnerId.getSObjectType() != User.sObjectType && emailUserId != null){
                                                    existLead.OwnerId = emailUserId;
                                                }
    
                                                Boolean isUpdateCS = false;
                                                Integer lastAssignedIndex = (insApi.last_assigned_index__c != null) ? Integer.valueOf(insApi.last_assigned_index__c) : -1;
                                                InstandaUtility.GetOwnerWrapper ownerWrap = InstandaUtility.getOwnerId(lastAssignedIndex);
                
                                                Database.LeadConvert lc = new database.LeadConvert();
                                                lc.setLeadId(existLead.Id);
                
                                              if(existLead.OwnerId.getSObjectType() != User.sObjectType){
                                                    isUpdateCS = true;
                                                    lc.setOwnerId(ownerWrap.ownerId);
                                                }
                
                                                LeadStatus convertStatus = [SELECT Id, ApiName FROM LeadStatus WHERE IsConverted=true LIMIT 1];
                                                lc.setConvertedStatus(convertStatus.ApiName);

                                                try{
                                                    Database.LeadConvertResult lcr = Database.convertLead(lc);
                                                    if(lcr.isSuccess()){
                                                        createOpp = true;
                                                        processOppId = lcr.getOpportunityId();
                                                        
                                                        if(isUpdateCS){
                                                            insApi.Last_Assigned_Index__c = String.valueOf(ownerWrap.lastAssignedIndex);
                                                            update insApi;
                                                        }
                                                    }
                                                }catch(Exception ex){
                                                    Database.rollback(sp);
        
                                                    resp.success = false;
                                                    resp.errorMessage = ex.getMessage() + ' line ' + ex.getLineNumber();
                                                    rest.statusCode = 500;
                                                    
                                                    notifyUsers(null, resp.errorMessage, reqBody);
                                                }
                                            }
                                        }
                                    }
                                }

                                if(processOppId != null){
                                    //perform logic here
                                    if(createOpp){
                                        Boolean isFound = false;
                                        List<Opportunity> processOpps = [SELECT Id, Name, Product_Type__c, Account.PersonEmail, LeadSource, (SELECT Id FROM Quotes) 
                                                                        FROM Opportunity 
                                                                        WHERE Id =:processOppId 
                                                                        AND Product_Type__c != null 
                                                                        AND AccountId != null 
                                                                        LIMIT 1];
                                        if(!processOpps.isEmpty()){
                                            Opportunity processOpp = processOpps[0];
                                            if(processOpp.LeadSource != 'API'){
                                                processOpp.LeadSource = 'API';
                                                update processOpp;
                                            }
                                            
                                            Quote qt = InstandaUtility.collectQuote(payload);
                                            qt.OpportunityId = processOpp.Id;
                                            qt.Name = processOpp.Name + processOpp.Quotes.size() + 1;
                                            if(emailUserId != null){
                                                qt.OwnerId = emailUserId;
                                            }
                                            insert qt;

                                            if(payload.PackageName.contains('IR35')){
                                                Attribution__c att = InstandaUtility.collectAttribution(payload);
                                                att.Name = processOpp.Name;
                                                att.Opportunity__c = processOppId;
                                                att.Lead_Source__c = processOpp.LeadSource;
                                                insert att;
                                            }

                                            List<Lead> openLeads = [SELECT Id, Name, Email, Phone, Street, City, PostalCode, Country, Product_Type__c, Product_Code__c, Referred_By__c, Referred_By_Email__c, Source__c, LeadSource
                                                                    FROM Lead 
                                                                    WHERE Email =: processOpp.Account.PersonEmail
                                                                    AND Product_Type__c INCLUDES (:processOpp.Product_Type__c)
                                                                    AND (Status = 'New' OR Status = 'Working')
                                                                    AND isConverted = false
                                                                    ORDER BY CreatedDate DESC];
                                            if(!openLeads.isEmpty()){
                                                isFound = true;
                                                for(Lead ld : openLeads){
                                                    Lead_Delete_Request__e deleteRequest = new Lead_Delete_Request__e(
                                                        LeadId__c = ld.Id,
                                                        OpportunityId__c = processOppId
                                                    );
                                                    Database.SaveResult result = EventBus.publish(deleteRequest);
                                                }
                                            }

                                            if(!isFound){
                                                List<Lead> unqualifiedLeads = [SELECT Id, Name, Email, Phone, Street, City, PostalCode, Country, Product_Type__c, Product_Code__c, Referred_By__c, Referred_By_Email__c, Source__c, LeadSource
                                                                    FROM Lead 
                                                                    WHERE Email =: processOpp.Account.PersonEmail
                                                                    AND Product_Type__c INCLUDES (:processOpp.Product_Type__c)
                                                                    AND Status = 'Unqualified'
                                                                    AND Unqualified_Date__c > :Date.today().addDays(-30)
                                                                    AND isConverted = false
                                                                    ORDER BY CreatedDate DESC];
                                                if(!unqualifiedLeads.isEmpty()){
                                                    isFound = true;
                                                    for(Lead ld : unqualifiedLeads){
                                                        Lead_Delete_Request__e deleteRequest = new Lead_Delete_Request__e(
                                                            LeadId__c = ld.Id,
                                                            OpportunityId__c = processOppId
                                                        );
                                                        Database.SaveResult result = EventBus.publish(deleteRequest);
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    if(String.isNotBlank(payload.PackageName)){
                                        Decimal quoteValue = (payload.PackageName.contains('IR35')) ? payload.IR35StatusToolFee : payload.TotalPremium;
                                        if(isValid(quoteValue)){
                                            //only create a quote/ quote line item when this is populated
                                            List<PricebookEntry> entries = [SELECT Id, Product2Id 
                                                                                FROM PricebookEntry 
                                                                                WHERE Product2.Name =: payload.PackageName 
                                                                                AND Product2.isActive = true 
                                                                                LIMIT 1];
                                            if(!entries.isEmpty()){
                                                List<Quote> quotes = [SELECT Id FROM Quote WHERE INSTANDA_Quote_ID__c =: payload.QuoteRef AND OpportunityId =: processOppId LIMIT 1];
                                                if(!quotes.isEmpty()){
                                                    Id quoteId = quotes[0].Id;

                                                    Quote qt = InstandaUtility.collectQuote(payload);
                                                    qt.Status = 'Quote Provided';
                                                    qt.Id = quoteId;
                                                    update qt;

                                                    List<QuoteLineItem> quoteItems = [SELECT Id  
                                                                            FROM QuoteLineItem 
                                                                            WHERE Product2.Name =: payload.PackageName
                                                                            AND QuoteId =: quoteId
                                                                            LIMIT 1];

                                                    if(!quoteItems.isEmpty()){
                                                        QuoteLineItem qtLine = quoteItems[0];
                                                        qtLine.UnitPrice = quoteValue;
                                                        update qtLine;
                                                    }else{
                                                        QuoteLineItem qtLine = InstandaUtility.collectQuoteItem(payload);
                                                        qtLine.QuoteId = quoteId;
                                                        qtLine.UnitPrice = quoteValue;
                                                        qtLine.Quantity = 1;
                                                        qtLine.PricebookEntryId = entries[0].Id;
                                                        insert qtLine;
                                                    }

                                                    Opportunity opp = new Opportunity(Id=processOppId);
                                                    opp.SyncedQuoteId = quoteId;
                                                    opp.CloseDate = (qt.ExpirationDate != null) ? qt.ExpirationDate : Date.today().addDays(Integer.valueOf(insApi.close_date_add_days__c));
                                                    update opp;
                                                }else{
                                                    resp.success = false;
                                                    resp.errorMessage = 'No matching quote with this reference - ' + payload.QuoteRef;
                                                    rest.statusCode = 503;
                                                    notifyUsers(null, resp.errorMessage, reqBody);                                               
                                                }
                                            }else{
                                                resp.success = false;
                                                resp.errorMessage = 'No matching pricebook entry with this package - ' + payload.PackageName;
                                                rest.statusCode = 503;
                                                notifyUsers(null, resp.errorMessage, reqBody);                                               
                                            }
                                        }
                                    }else{
                                        resp.success = false;
                                        resp.errorMessage = 'No product mapping for package - ' + payload.PackageName;
                                        rest.statusCode = 503;
                                        notifyUsers(null, resp.errorMessage, reqBody);
                                    }
                                }
                            }

                            //Case for offline payment Applicable for New Business, Renewals and MTA
                            if(isValid(payload.PaymentType) && isValid(payload.SaleStage)){
                                Set<String> saleStages = new Set<String>{'SaleComplete', 'PolicyNumberGenerated', 'PaymentMade'};
                                if(payload.PaymentType == 'Offline' && saleStages.contains(payload.SaleStage)){

                                    if(isValid(payload.TotalPayable) && payload.TotalPayable != 0.00){
                                    
                                        system.debug('***Offline case');
                                        createOfflineCase(payload);
                                    }
                                }
                            }
                        }
                    }else{
                        resp.success = false;
                        resp.errorMessage = 'Unauthorized';
                        rest.statusCode = 401;

                        notifyUsers(null, '401 - Unauthorized', reqBody);
                    }
                }else{
                    resp.success = false;
                    resp.errorMessage = 'Forbidden';
                    rest.statusCode = 403;

                    notifyUsers(null, '403 - Forbidden', reqBody);
                }
            }
        }catch(Exception ex){
            Database.rollback(sp);

            resp.success = false;
            resp.errorMessage = ex.getMessage() + ' line ' + ex.getLineNumber();
            rest.statusCode = 500;
            
            System.debug('@@@resp.errorMessage: ' + resp.errorMessage);
            System.debug('@@@ex.getStackTraceString(): ' + ex.getStackTraceString());
            
            notifyUsers(null, resp.errorMessage, reqBody);
        }

        if(!Test.IsRunningTest()){
            rest.responseBody = Blob.valueOf(JSON.serialize(resp, true));
        }
    }

    public static Boolean isValid(Object obj){
        Boolean isValid = false;
        if(obj instanceof String){
            if(obj != null && obj != ''){
                isValid = true;
            }
        }else{
            if(obj != null){
                isValid = true;
            }
        }
        return isValid;
    }

    public static void notifyUsers(Id objId, String descr, String payload) {
        Id groupId = null;
        
        Set<String> userIds = new Set<String>();
        Map<Id, Group> grpIdToGrpMap = InstandaUtility.groupIdToGroupMap('API Errors Queue');
        if(!grpIdToGrpMap.isEmpty()){        
            groupId = new List<Id>(grpIdToGrpMap.keyset())[0];
            Group grp = grpIdToGrpMap.get(groupId);
            for(GroupMember member : grp.GroupMembers){
                if(member.UserOrGroupId.getsObjectType() == Schema.User.sObjectType){
                    userIds.add(member.UserOrGroupId);
                } 
            }
        }

        if(!userIds.isEmpty()){
            Task tsk = new Task();
            tsk.Subject = 'Instanda API Error!';
            tsk.Description = descr + '\n\n' + payload;
            tsk.ActivityDate = Date.today();
            tsk.OwnerId = groupId;
            tsk.Priority = 'High';
            tsk.Status = 'Open';
            if(objId != null){
                if(objId.getSObjectType() == Lead.sObjectType){
                    tsk.WhoId = objId;
                }else{
                    tsk.WhatId = objId;
                }
            }
            insert tsk;
    
            // Get the Id for our custom notification type
            CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType 
                                                        WHERE DeveloperName = 'Instanda_API_Notification'];
            
            // Create a new custom notification
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
    
            // Set the contents for the notification
            notification.setTitle('Instanda API Error!');
    
            notification.setBody('The Instanda API has produced an error. Click here to review the error details.');
    
            // Set the notification type and target
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(tsk.Id);
            
            // Actually send the notification
            try {
                notification.send(userIds);
            }catch (Exception ex) {
                System.debug('Problem sending notification: ' + ex.getMessage());
            }
        }
    }

    public class ResponseHandler{
        public Boolean success;
        public String errorMessage;
    }


    public static void opportunityReferred(Id oppId, Id accId, Id conId, Opportunity parentOpp, InstandaUtility.RequestHandler payload, Id underwritingRecordTypeId){
        Boolean hasProcessed = false;
        Boolean updateQuote = false;
        if(isValid(payload.Referred)){
            if(payload.Referred && !parentOpp.Referred__c && parentOpp.Cases__r.isEmpty()){

                hasProcessed = true;
                updateQuote = true;

                //create a case
                Case cs = InstandaUtility.collectCase(payload);
                cs.AccountId = accId;
                cs.ContactId = conId;
                cs.Subject = 'Referral' + ' - ' + payload.QuoteRef;
                cs.RecordTypeId = underwritingRecordTypeId;
                cs.Opportunity__c = parentOpp.Id;
                if(!Test.isRunningTest()){
                    cs.OwnerId = new List<Id>(InstandaUtility.groupIdToGroupMap(payload.IsRenewal ? 'Renewals' : 'New Business - Contractor').keyset())[0];
                }
                cs.Status = 'New';
                insert cs;

                parentOpp.Referred__c = true;
                update parentOpp;
            }
        }

        if(!hasProcessed){
            Boolean isChangedToFalse = false;
            if(isValid(payload.Referred)){
                if((parentOpp.Referred__c != payload.Referred && !payload.Referred)){
                    isChangedToFalse = true;
                    updateQuote = true;

                    parentOpp.Referred__c = false;
                    update parentOpp;
                }
            }
        }

        if(isValid(payload.Referred) && updateQuote){
            if(parentOpp.Id != null){
                if(parentOpp.SyncedQuoteId != null){
                    Quote updateQt = new Quote(Id=parentOpp.SyncedQuoteId);
                    if(payload.Referred){
                        updateQt.Status = 'Quote Referred';
                    }else{
                        if(payload.SaleStage == 'Quote'){
                            updateQt.Status = 'Quote Provided';
                        }
                    }
                    update updateQt;
                }
            }
        }
    }

    public static Boolean isMTAPolicyProcess(InstandaUtility.RequestHandler payload,  List<Policy__c> policies, Opportunity parentOpp, Id accId){
        Boolean insertPolicyMTA = false;

        if(isValid(payload.IsMTA) && isValid(payload.SaleStage)){

            Datetime expDatetime = InstandaUtility.convertToUTCDateTime(payload.EffectiveUntilDate);
            insertPolicyMTA = payload.IsMTA;
            
            if(insertPolicyMTA == true && (payload.SaleStage == 'PolicyNumberGenerated' || payload.SaleStage == 'PaymentMade') && parentOpp != null){
                
                Policy__c polOriginal = policies[0];
                polOriginal.Status__c = 'Superseded';
                polOriginal.Id = policies[0].Id;
                update polOriginal;

                Policy__c polNew = InstandaUtility.collectPolicy(payload, accId, parentOpp.OwnerId);
                polNew.From_Opportunity__c = parentOpp.Id;
                polNew.Status__c = 'Live';
                insert polNew;

                Opportunity opp = new Opportunity();
                opp.Id = parentOpp.Id;
                opp.StageName = 'Closed Won';
                update opp;
            } 
        }

        return insertPolicyMTA;
    }

    public static Boolean isRenewalPolicyProcess(InstandaUtility.RequestHandler payload,  List<Policy__c> policies, Opportunity parentOpp, Id accId){
        Boolean insertPolicyRenewal = false;

        if(isValid(payload.IsRenewal) && isValid(payload.SaleStage)){
            insertPolicyRenewal = payload.IsRenewal;
            
            if(insertPolicyRenewal == true && (payload.SaleStage == 'PolicyNumberGenerated' || payload.SaleStage == 'PaymentMade') && parentOpp != null){

                Policy__c polRenewal = InstandaUtility.collectPolicy(payload, accId, parentOpp.OwnerId);
                polRenewal.From_Opportunity__c = parentOpp.Id;
                polRenewal.Status__c = 'Live';
                insert polRenewal;

            }
        }

        return insertPolicyRenewal;
    }

    public static Boolean isNewBusinessPolicyProcess(InstandaUtility.RequestHandler payload,  List<Policy__c> policies, Opportunity parentOpp, Id accId){
        Boolean insertPolicyNewBusiness = false;

        if(isValid(payload.CreatedFrom) && isValid(payload.SaleStage)){
            insertPolicyNewBusiness = payload.CreatedFrom=='NewBusiness'?true:false;
            
            if(insertPolicyNewBusiness == true && (payload.SaleStage == 'PolicyNumberGenerated' || payload.SaleStage == 'PaymentMade') && parentOpp != null){
                
                Policy__c polNewBusiness = InstandaUtility.collectPolicy(payload, accId, parentOpp.OwnerId);
                polNewBusiness.From_Opportunity__c = parentOpp.Id;
                polNewBusiness.Status__c = 'Live';
                insert polNewBusiness;

                Opportunity opp = new Opportunity();
                opp.Id = parentOpp.Id;
                opp.StageName = 'Closed Won';
                update opp;
            }
        }

        return insertPolicyNewBusiness;
    }

    public static void noExistingPolicyProcess(Opportunity parentOpp, Id accId, InstandaUtility.RequestHandler payload, InstandaApi__c insApi, ResponseHandler resp, RestResponse rest, String reqBody){
        if(parentOpp.Id != null){

            if(isValid(payload.SaleStage) && (payload.SaleStage == 'PolicyNumberGenerated' || payload.SaleStage == 'SaleComplete')){
                Policy__c pol = InstandaUtility.collectPolicy(payload, accId, parentOpp.OwnerId);
                pol.From_Opportunity__c = parentOpp.Id;
                pol.Status__c = 'Live';
                insert pol;

                Id quoteId = null;
                Date expirationDate = null;
                
                List<Quote> quotes = [SELECT Id, ExpirationDate FROM Quote WHERE INSTANDA_Quote_ID__c =: payload.QuoteRef AND OpportunityId =: parentOpp.Id LIMIT 1];
                if(!quotes.isEmpty()){
                    quoteId = quotes[0].Id;
                    expirationDate = quotes[0].ExpirationDate;

                    Quote qt = quotes[0];
                    qt.Status = 'Policy - Live';
                    update qt;
                }

                
                Opportunity opp = InstandaUtility.collectOpp(payload);
                opp.Id = parentOpp.Id;
                if(quoteId != null){
                    opp.SyncedQuoteId = quoteId;
                    opp.CloseDate = (expirationDate != null) ? expirationDate : Date.today().addDays(Integer.valueOf(insApi.close_date_add_days__c));
                }
                opp.StageName = 'Closed Won';
                update opp;
            }
        }else{
            resp.success = false;
            resp.errorMessage = 'No open opportunity with ' + payload.QuoteRef;
            rest.statusCode = 503;

            notifyUsers(accId, resp.errorMessage, reqBody);
        }
    }

    public static void createOfflineCase(InstandaUtility.RequestHandler payload){

        String offlineUserId = '';
        List<User> usersForOffline = [SELECT Id FROM User WHERE Email =: payload.SaleCompletedBySalesPersonEmail AND isActive = true LIMIT 1];
        if(!usersForOffline.isEmpty()){
            offlineUserId = usersForOffline[0].Id;
        }else{
            Group myQueue = [SELECT Id FROM Group WHERE Name = 'Customer Support' AND Type = 'Queue' LIMIT 1];
            offlineUserId = myQueue.Id;
        }

        List<Opportunity> opps = [SELECT Id, AccountId, Name, INSTANDA_Quote_ID__c
                                FROM Opportunity 
                                WHERE INSTANDA_Quote_ID__c =: payload.QuoteRef
                                LIMIT 1];

        Case offlineCase = new Case();
        offlineCase.RecordTypeId = InstandaUtility.getRecordTypeIdbyName('Case', 'Customer Support');
        offlineCase.OwnerId = offlineUserId;
        offlineCase.Subject = 'Offline Payment - ' + payload.QuoteRef;
        offlineCase.Opportunity__c = !opps.isEmpty()?opps[0].Id:null;
        if(!opps.isEmpty() && opps[0].AccountId != null){
            Account acc = [SELECT Id, PersonContactId FROM Account WHERE Id =: opps[0].AccountId LIMIT 1];
            offlineCase.AccountId = acc.Id;
            offlineCase.ContactId = acc.PersonContactId != null ? acc.PersonContactId : null;
        }
        // offlineCase.AccountId = !opps.isEmpty()?opps[0].AccountId!=null?opps[0].AccountId:null:null;
        offlineCase.Description = '"Create CST: Manual DD" task attached to this case, requesting for customer service to set up payment. Ensure you have completed all relevant payment information needed.';
        offlineCase.Origin = 'Web';

        String offlineCaseComments = '';
        if(isValid(payload.TotalPayable)){
            Decimal total = payload.TotalPayable.setScale(2);
            offlineCaseComments = '£' + String.valueOf(total);
        }else{
            offlineCaseComments = '£0.00';
        }
        offlineCase.Comments = offlineCaseComments;

        insert offlineCase;
    }
}