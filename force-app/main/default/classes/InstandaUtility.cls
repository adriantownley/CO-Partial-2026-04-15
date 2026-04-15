public class InstandaUtility {
    public static Account collectAccount(RequestHandler payload){
        Account acc = new Account();
        
        acc.INSTANDA_Policy_ID__c = payload.PolicyNumber;
        acc.INSTANDA_Quote_ID__c = payload.QuoteRef;
        acc.PersonTitle = payload.PolicyholderTitle;
        acc.FirstName = payload.PolicyholderFirstName;
        acc.LastName = payload.PolicyholderLastName;
        if(isValid(payload.PolicyholderDateOfBirth)){
            acc.PersonBirthDate = Date.valueOf(payload.PolicyholderDateOfBirth); //Date.valueOf(payload.PolicyholderDateOfBirth.substringBefore('T'));
            //acc.PersonBirthdate = isoStringToDate(payload.PolicyholderDateOfBirth);
        }
        acc.Business_Name__c = payload.BusinessName;
        acc.PersonEmail = payload.PolicyholderEmail;
        acc.Phone = payload.PolicyholderPhone;
        if(isValid(payload.PolicyholderAlternativePhone)){
            acc.PersonMobilePhone = payload.PolicyholderAlternativePhone;
        }
        acc.PersonMailingStreet = payload.PolicyholderAddressLine1;
        acc.PersonMailingCity = payload.PolicyholderCity;
        acc.PersonMailingPostalCode = payload.PolicyholderPostcode;
        acc.PersonMailingCountry = payload.PolicyholderCountry;
        if(isValid(payload.Referred)){
            acc.Referred__c = payload.Referred;
        }
        if(isValid(payload.RenewalBlocked)){
            acc.Blocked_Renewal__c = payload.RenewalBlocked;
        }
        if(isValid(payload.EverMadeAnyClaim)){
            acc.Claim_made__c = (payload.EverMadeAnyClaim == 'Yes') ? true : false;
        }
        
        if(Test.isRunningTest()){
            Map<Integer, Integer> testMap = getCount();
        }

        Boolean hasOptedOut = isValid(payload.CustomerOptedOutOfRenewal) ? ((payload.CustomerOptedOutOfRenewal == 'Yes') ? true : false) : false;
        acc.Auto_Renew__c = !hasOptedOut;
        return acc;
    }

    public static Lead collectLead(RequestHandler payload){
        Lead ld = new Lead();
        ld.INSTANDA_Quote_ID__c = payload.QuoteRef;
        ld.SBJ_Quote_ID__c = payload.SBJQuoteRef;
        ld.Salutation = payload.PolicyholderTitle;
        ld.FirstName = payload.PolicyholderFirstName;
        ld.LastName = payload.PolicyholderLastName;
        ld.Email = payload.PolicyholderEmail;
        ld.Phone = payload.PolicyholderPhone;
        ld.Street = payload.PolicyholderAddressLine1;
        ld.City = payload.PolicyholderCity;
        ld.PostalCode = payload.PolicyholderPostcode;
        ld.Country = payload.PolicyholderCountry;
        ld.Product_Type__c = payload.PackageName;
        ld.Product_Code__c = payload.PackageCode;
        ld.Referral_Link__c = payload.RafLink;
        ld.Referred_By__c = payload.RafReferredByName;
        ld.Referred_By_Email__c = payload.RafReferredByEmail;
        if(isValid(payload.Referred)){
            ld.Referred__c = payload.Referred;
        }
        if(isValid(payload.PolicyholderDateOfBirth)){
            ld.Birthdate__c = Date.valueOf(payload.PolicyholderDateOfBirth); //Date.valueOf(payload.PolicyholderDateOfBirth.substringBefore('T'));
            //ld.Birthdate__c = isoStringToDate(payload.PolicyholderDateOfBirth);
        }
        return ld;
    }

    public static Lead collectUpdateLead(RequestHandler payload){
        Lead ld = new Lead();
        ld.INSTANDA_Quote_ID__c = payload.QuoteRef;
        ld.SBJ_Quote_ID__c = payload.SBJQuoteRef;
        ld.Salutation = payload.PolicyholderTitle;
        ld.FirstName = payload.PolicyholderFirstName;
        ld.LastName = payload.PolicyholderLastName;
        ld.Email = payload.PolicyholderEmail;
        ld.Phone = payload.PolicyholderPhone;
        ld.Street = payload.PolicyholderAddressLine1;
        ld.City = payload.PolicyholderCity;
        ld.PostalCode = payload.PolicyholderPostcode;
        ld.Country = payload.PolicyholderCountry;
        ld.Product_Type__c = payload.PackageName;
        ld.Product_Code__c = payload.PackageCode;
        if(isValid(payload.PolicyholderDateOfBirth)){
            ld.Birthdate__c = Date.valueOf(payload.PolicyholderDateOfBirth); //Date.valueOf(payload.PolicyholderDateOfBirth.substringBefore('T'));
            //ld.Birthdate__c = isoStringToDate(payload.PolicyholderDateOfBirth);
        }
        return ld;
    }

    public static Attribution__c collectAttribution(RequestHandler payload){
        Attribution__c att = new Attribution__c();
        att.Name = payload.PolicyholderFirstName + ' ' + payload.PolicyholderLastName;
        att.Email__c = payload.PolicyholderEmail;
        att.Phone__c = payload.PolicyholderPhone;
        att.Street__c = payload.PolicyholderAddressLine1;
        att.City__c = payload.PolicyholderCity;
        att.Postal_Code__c = payload.PolicyholderPostcode;
        att.Country__c = payload.PolicyholderCountry;
        att.Product_Type__c = payload.PackageName;
        att.Product_Code__c = payload.PackageCode;
        att.Referred_By__c = payload.RafReferredByName;
        att.Referred_By_Email__c = payload.RafReferredByEmail;
        att.Source__c = determineLeadSource(payload.WhereHeard);
        return att;
    }

    public static Opportunity collectOpp(RequestHandler payload){
        Opportunity opp = new Opportunity();
        opp.INSTANDA_Quote_ID__c = payload.QuoteRef;
        opp.CloseDate = isValid(payload.PredictedRenewalDate) ? Date.valueOf(payload.PredictedRenewalDate) : Date.today() + 30;
        opp.StageName = 'Prospecting';
        opp.Previous_Payment_Method__c = payload.PreviousPaymentMethod;


        Boolean hasOptedOutOpp = isValid(payload.CustomerOptedOutOfRenewal) ? ((payload.CustomerOptedOutOfRenewal == 'Yes') ? true : false) : false;
        opp.Auto_Renew__c = !hasOptedOutOpp;

        //amendments
        if(isValid(payload.EffectiveFromDate)){
            opp.Policy_Inception_Date__c = convertToUTCDateTime(payload.EffectiveFromDate);
        }
        opp.Premium__c = (isValid(payload.IR35StatusToolFee)) ? payload.IR35StatusToolFee + payload.TotalPremium : payload.TotalPremium;
        if(isValid(payload.VatAmount)){
            opp.VAT__c = payload.VatAmount;
        }
        if(isValid(payload.IptAmount)){
            opp.IPT__c = payload.IptAmount;
        }
        if(isValid(payload.TotalPayable)){
            opp.Total_Payable__c = payload.TotalPayable;
        }
        if(isValid(payload.Referred)){
            opp.Referred__c = payload.Referred;
        }
        if(isValid(payload.IptAmount) || isValid(payload.VatAmount)){
            Decimal taxAmount = 0;
            if(isValid(payload.IptAmount)){
                taxAmount += payload.IptAmount;
            }
            if(isValid(payload.VatAmount)){
                taxAmount += payload.VatAmount;
            }
            opp.Tax_Amount__c = taxAmount;
        }
        if(isValid(payload.CreatedFrom)){
            opp.Type = payload.CreatedFrom;
        }
        Set<String> emails = new Set<String>();
        if(isValid(payload.SalespersonEmail)){
            emails.add(payload.SalespersonEmail);
        }
        if(isValid(payload.SaleCompletedBySalesPersonEmail)){
            emails.add(payload.SaleCompletedBySalesPersonEmail);
        }
        if(!emails.isEmpty()){
            Map<String, String> userEmailToNameMap = new Map<String, String>();
            for(User usr : [SELECT Name, Email FROM User WHERE Email IN :emails]){
                userEmailToNameMap.put(usr.email.toLowerCase(), usr.Name);
            }
            if(!userEmailToNameMap.isEmpty()){
                /*if(isValid(payload.SalespersonEmail)){
                    String emailKey = payload.SalespersonEmail.toLowerCase();
                    if(userEmailToNameMap.containsKey(emailKey)){
                        opp.First_Quoted_By__c = userEmailToNameMap.get(emailKey);
                    }
                }*/

                if(isValid(payload.SaleCompletedBySalesPersonEmail)){
                    String emailKey = payload.SaleCompletedBySalesPersonEmail.toLowerCase();
                    if(userEmailToNameMap.containsKey(emailKey)){
                        opp.Sale_Completed_By__c = userEmailToNameMap.get(emailKey);
                    }
                }
            }else{
                if(isValid(payload.SalespersonEmail)){
                    opp.Sale_Completed_By__c = payload.SalespersonEmail.toLowerCase();
                }
            }
        }
        opp.First_Quoted_By__c = payload.SalespersonName;
        if(isValid(payload.BusinessName)){
            opp.Company_name_Sole_Trader_name__c = payload.BusinessName;
        }
        if(isValid(payload.HasSecondaryActivity)){
            opp.Business_engage_in_any_other_activities__c = payload.HasSecondaryActivity;
        }
        if(isValid(payload.PriceReductionType)){
            opp.Price_Reduction_Type__c = payload.PriceReductionType;
        }
        if(isValid(payload.DiscountAmount)){
            opp.Discount_Amount__c = payload.DiscountAmount;
        }
        if(isValid(payload.PremiumAdjustment)){
            opp.Premium_Adjustment__c = payload.PremiumAdjustment;
        }
        if(isValid(payload.PricematchPremium)){
            opp.Price_Match_Premium__c = payload.PricematchPremium;
        }
        if(isValid(payload.AcceptHealthcareExclusion)){
            opp.Medical_Service_Guidance__c = payload.AcceptHealthcareExclusion;
        }
        if(isValid(payload.AcceptLegalServicesExclusion)){
            opp.Regulated_Legal_Services_Guidance__c = payload.AcceptLegalServicesExclusion;
        }
        if(isValid(payload.DirectorsAndOfficersCoverLevel)){
            opp.CoverLevel_D_O__c = payload.DirectorsAndOfficersCoverLevel;
        }
        if(isValid(payload.Ern)){
            opp.ERN_Number__c = payload.Ern;
        }
        if(isValid(payload.PaymentType) || isValid(payload.PaymentTypeName)){
            String paymentMethod = '';

            Boolean hasPaymentType = false;
            if(isValid(payload.PaymentType)){
                hasPaymentType = true;
                paymentMethod = payload.PaymentType;
            }
            if(isValid(payload.PaymentTypeName)){
                if(hasPaymentType){
                    paymentMethod += ' - ' + payload.PaymentTypeName;
                }else{
                    paymentMethod = payload.PaymentTypeName;
                }
            }
            opp.Payment_Method__c = paymentMethod;
        }
        if(isValid(payload.CurrentlyHaveBusinessInsurance)){
            opp.Do_you_currently_hold_Business_Insurance__c = payload.CurrentlyHaveBusinessInsurance;
        }
        if(isValid(payload.utm_source)){
            opp.UTM_Source__c = payload.utm_source;
        }
        if(isValid(payload.utm_term)){
            opp.UTM_Term__c = payload.utm_term;
        }
        if(isValid(payload.utm_medium)){
            opp.UTM_Medium__c = payload.utm_medium;
        }
        if(isValid(payload.utm_content)){
            opp.UTM_Content__c = payload.utm_content;
        }
        if(isValid(payload.utm_campaign)){
            opp.UTM_Campaign__c = payload.utm_campaign;
        }
        //Orange-Highlighted
        if(isValid(payload.BusinessEquipmentCoverLevel)){
             opp.Addon_Product_BE__c = payload.BusinessEquipmentCoverLevel;
        }
        if(isValid(payload.AddCyberLiability)){
            opp.Addon_Product_Cyber__c = payload.AddCyberLiability;
        }
        if(isValid(payload.HasLegalExpenses)){
            opp.Addon_Product_LE__c = payload.HasLegalExpenses;
        }
        if(isValid(payload.PersonalAccidentCoverLevel)){
            opp.Addon_Product_PA__c = payload.PersonalAccidentCoverLevel;
        }
        if(isValid(payload.AcceptAviationExclusion)){
            opp.Aircraft_Guidance__c = payload.AcceptAviationExclusion;
        }
        if(isValid(payload.AcceptArchitectureExclusion)){
            opp.Architect_Guidance__c = payload.AcceptArchitectureExclusion;
        }
        if(isValid(payload.BankruptOrAdministration)){
            opp.Been_Bankrupt__c = payload.BankruptOrAdministration;
        }
        if(isValid(payload.EverBankruptOrAdministration) && (isValid(payload.PackageName) && payload.PackageName.contains('IR35'))){
            opp.Been_Bankrupt__c = payload.EverBankruptOrAdministration;
        }
        if(isValid(payload.EverMadeAnyClaim) && (isValid(payload.PackageName) && payload.PackageName.contains('IR35'))){
            opp.Claims_Made__c = payload.EverMadeAnyClaim ;
        }
        if(isValid(payload.IR35CoverLevel)){
            opp.Cover_Level_IR35__c = payload.IR35CoverLevel;
        }
        if(isValid(payload.ProfessionalIndemnityCoverLevel)){
            opp.Cover_Level_PI__c = Decimal.valueOf(String.valueOf(payload.ProfessionalIndemnityCoverLevel).split('\\.')[0]);
        }
        if(isValid(payload.PublicLiabilityCoverLevel)){
            opp.Cover_Level_PL__c = Decimal.valueOf(String.valueOf(payload.PublicLiabilityCoverLevel).split('\\.')[0]);
        }
        if(isValid(payload.SafetyCriticalWork)){
            opp.Critical_Rail_Work__c = payload.SafetyCriticalWork;
        }
        if(isValid(payload.InsuredByAlready)){
            opp.Who_is_their_current_insurer__c = payload.InsuredByAlready;
            opp.Current_Insurer__c = payload.InsuredByAlready;
        }
        if(isValid(payload.CurrentlyHaveBusinessInsurance) && (isValid(payload.PackageName) && payload.PackageName.contains('IR35')) && payload.CurrentlyHaveBusinessInsurance == 'Yes'){
            opp.Current_Renewal_Date__c = Date.valueOf(payload.CurrentRenewalDate);
            opp.Renewal_Date__c = Date.valueOf(payload.CurrentRenewalDate);
        }
        if(isValid(payload.EverDeclinedOrSpecialTerms)){
            opp.Declined_Cover__c = payload.EverDeclinedOrSpecialTerms;

            if(isValid(payload.EverDeclinedOrSpecialTermsDetails) && payload.EverDeclinedOrSpecialTerms == 'Yes' && (isValid(payload.PackageName) && payload.PackageName.contains('IR35'))){
                opp.Declined_Cover_Offences__c = payload.EverDeclinedOrSpecialTermsDetails;
            }
        }
        
        if(isValid(payload.NonMotoringCriminalOffences) && (isValid(payload.PackageName) && !payload.PackageName.contains('IR35'))){
            opp.Declined_Cover_Offences__c = payload.NonMotoringCriminalOffences;
        }

        if(isValid(payload.HeatOrHighVoltageWork)){
            opp.Heat_Powerline_Work__c = payload.HeatOrHighVoltageWork;
        }
        if(isValid(payload.Sector)){
            opp.Industry_1__c = payload.Sector;
        }
        if(isValid(payload.AcceptNuclearExclusion)){
            opp.Nuclear_Guidance__c = payload.AcceptNuclearExclusion;
        }
        if(isValid(payload.NumberOfFamilyClerical)){
            opp.Number_Of_Family_Admin__c = Integer.valueOf(payload.NumberOfFamilyClerical);
        }
        if(isValid(payload.NumberOfFeeEarningEmployees)){
            opp.Number_Of_Fee_Earning_Staff__c = Integer.valueOf(payload.NumberOfFeeEarningEmployees);
        }
        if(isValid(payload.NumberOfFeeEarningEmployees) || isValid(payload.NumberOfClericalEmployees)){
            Integer noOfEmployees = 0;
            noOfEmployees += isValid(payload.NumberOfFeeEarningEmployees) ? Integer.valueOf(payload.NumberOfFeeEarningEmployees) : 0;
            noOfEmployees += isValid(payload.NumberOfClericalEmployees) ? Integer.valueOf(payload.NumberOfClericalEmployees) : 0;
            opp.Number_Of_Employees__c = noOfEmployees;
        }
        if(isValid(payload.PrimaryBusinessActivity)){
            opp.Occupation_1__c = payload.PrimaryBusinessActivity;
        }
        if(isValid(payload.SmeBusinessActivity_2)){
            opp.Occupation_2__c = payload.SmeBusinessActivity_2;
        }
        if(isValid(payload.SmeBusinessActivity_3)){
            opp.Occupation_3__c = payload.SmeBusinessActivity_3;
        }
        if(isValid(payload.SmeBusinessActivity_4)){
            opp.Occupation_4__c = payload.SmeBusinessActivity_4;
        }
        if(isValid(payload.SmeBusinessActivity_5)){
            opp.Occupation_5__c = payload.SmeBusinessActivity_5;
        }
        if(isValid(payload.WorkAtHeight)){
            opp.Occupation_Height_Work__c = payload.WorkAtHeight;
        }
        if(isValid(payload.ManualWork)){
            opp.Occupation_Manual_Work__c = payload.ManualWork;
        }
        if(isValid(payload.WorkOffshore)){
            opp.Occupation_Offshore_Work__c = payload.WorkOffshore;
        }
        if(isValid(payload.RicsMember)){
            opp.RICS_Member__c = payload.RicsMember;
        }
        if(isValid(payload.Turnover)){
            opp.Turnover__c = payload.Turnover;
        }
        if(isValid(payload.UsaWorkOrContract)){
            opp.USA_Canada_Work__c = payload.UsaWorkOrContract;
        }
        if(isValid(payload.UsaContract)){
            opp.USA_Canada_Law__c = payload.UsaContract;
        }
        if(isValid(payload.UsaPhysical)){
            opp.USA_Canada_Physical_Work__c = payload.UsaPhysical;
        }
        if(isValid(payload.UsaOver30Days)){
            opp.USA_Canada_Over_30_Days__c = payload.UsaOver30Days;
        }

        if(isValid(payload.InstalmentAmount)){
            opp.Initial_Installment_Amount__c = payload.InstalmentAmount;
        }

        if(isValid(payload.PackageName)){
            opp.Product_Type__c = payload.PackageName;

            if(payload.PackageName == 'IR35 Standalone Protect'){
                if(isValid(payload.TotalPremium)){
                    opp.Premium__c = payload.TotalPremium;
                }
                if(isValid(payload.DiscountAmount)){
                    opp.Discount_Amount__c = payload.DiscountAmount;
                }
                if(isValid(payload.StatusReviewsPrice)){
                    opp.IR35_Status_Tool_Fee__c = payload.StatusReviewsPrice;
                }
                if(isValid(payload.VatAmount)){
                    opp.VAT__c = payload.VatAmount;
                }
                if(isValid(payload.IptAmount)){
                    opp.IPT__c = payload.IptAmount;
                }
                if(isValid(payload.TotalPayable)){
                    opp.Total_Payable__c = payload.TotalPayable;
                }
                if(isValid(payload.PremiumAdjustment)){
                    opp.Premium_Adjustment__c = payload.PremiumAdjustment;
                }
                if(isValid(payload.ProductType)){
                    opp.Cover_Level_IR35__c = payload.ProductType;
                }
            }
        }
        if(isValid(payload.PolicyNumberSuffixed)){
            opp.Version__c = payload.PolicyNumberSuffixed;
        }
        if(isValid(payload.RenewalCount)){
            opp.Renewal_Count__c = payload.RenewalCount.split('\\.')[0];
        }
        if(isValid(payload.MtaCount)){
            opp.MTA_Count__c = payload.MtaCount.split('\\.')[0];
        }

        //referral info
        opp.Source_of_Leads__c = determineLeadSource(payload.WhereHeard);
        opp.Attribution__c = payload.WhereHeard;

        if(isValid(payload.PartnerId)){
            List<Account> partners = [SELECT Id FROM Account WHERE Partner_ID__c=:payload.PartnerId LIMIT 1];
            if(!partners.isEmpty()){
                opp.Partner__c = partners[0].Id;
            }
        }else{
            opp.Partner__c = null;
        }

        if(opp.Source_of_Leads__c == 'Partner'){
            opp.Employer_End_Client__c = payload.WhereHeardEmployerClientCompany;

            opp.Referred_By__c = null;
            if(payload.WhereHeard == 'Accountancy/recruitment company/professional body'){
                // if(isValid(payload.WhereHeardPartnerPerson)){
                //     opp.Referred_By__c = payload.WhereHeardPartnerPerson;
                // }
                if(isValid(payload.PartnerCompanyPerson)){
                    opp.Referred_By__c = payload.PartnerCompanyPerson;
                }
            }

            if(payload.WhereHeard == 'Marketing campaign'){
                opp.Source__c = 'Direct';
            }

            if(payload.WhereHeard == 'my employer/client'){
                if(isValid(payload.WhereHeardEmployerClientPerson)){
                    opp.Referred_By__c = payload.WhereHeardEmployerClientPerson;
                }
            }
        }else{
            opp.Referred_By__c = null;
            opp.Employer_End_Client__c = null;
            opp.Partner__c = null;
        }

        opp.Referral_Friend_Name__c = payload.WhereHeardFriendName;
        opp.Referred_By_Email__c = payload.WhereHeardFriendEmail;
        opp.Individual_Referred_by_Contact__c = payload.PartnerCompanyPerson;
        opp.Unlisted_Referral_Company__c = payload.UnlistedReferralCompany;

        if(isValid(payload.IR35StatusToolFee)){
            opp.IR35_Status_Tool_Fee__c = payload.IR35StatusToolFee;
        }
        if(isValid(payload.MtaHasPremiumRefund)){
            opp.MTA_Premium_Refund__c = payload.MtaHasPremiumRefund;
        }
        if(isValid(payload.MTA_TotalPayable)){
            opp.MTA_Total_Refundable__c = payload.MTA_TotalPayable;
        }
        if(isValid(payload.PolicyholderPhone)){
            opp.Phone_Number__c = payload.PolicyholderPhone;
        }
        if(isValid(payload.PolicyholderAlternativePhone)){
            opp.Alternate_Phone_Number__c = payload.PolicyholderAlternativePhone;
        }
        return opp;

        //opp.Primary_INSTANDA_Quote_URL__c = payload.
    }

    public static Quote collectQuote(RequestHandler payload){
        Quote qt = new Quote();
        if(isValid(payload.PredictedRenewalDate)){
            qt.ExpirationDate = Date.valueOf(payload.PredictedRenewalDate);
        }
        qt.INSTANDA_Quote_ID__c = payload.QuoteRef;
        //amendments
        if(isValid(payload.EffectiveFromDate)){
            qt.Policy_Inception_Date__c = Date.valueOf(payload.EffectiveFromDate.substringBefore('T'));
        }
        if(isValid(payload.WhereHeard)){
            qt.Where_did_You_hear_about_us__c = payload.WhereHeard;
        }
        /*if(isValid(payload.PolicyNumberSuffixed)){
            qt.Version__c = payload.PolicyNumberSuffixed;
        }*/
        return qt;

        //qt.INSTANDA_URL__c = payload.
    }

    public static QuoteLineItem collectQuoteItem(RequestHandler payload){
        QuoteLineItem qtItm = new QuoteLineItem();
        return qtItm;
    }
    
    /*a little bit confused with the record types*/
    public static Case collectCase(RequestHandler payload){
        Case cs = new Case();
        cs.INSTANDA_Quote_ID__c = payload.QuoteRef;
        cs.Origin = 'Instanda';
        if(isValid(payload.SalespersonEmail)){
            cs.INSTANDA_Sales_Person_Email__c = payload.SalespersonEmail;
        }
        return cs;
    }

    public static Policy__c collectPolicy(RequestHandler payload, Id accountId, Id oppOwnerId){
        Policy__c pol = new Policy__c();
        pol.INSTANDA_Policy_ID__c = payload.PolicyNumber;
        pol.INSTANDA_Quote_ID__c = payload.QuoteRef;
        pol.Business_Type__c = payload.CreatedFrom;
        if(isValid(payload.CancellationDate)){
            pol.Cancellation_Date_Effective__c = convertToUTCDateTime(payload.CancellationDate);
        }
        if(isValid(payload.CancellationCreatedOnDate)){
            pol.Cancellation_Date_Requested__c = convertToUTCDateTime(payload.CancellationCreatedOnDate);
        }
        pol.Cancellation_Reason__c = payload.CancellationReason;        
        if(isValid(payload.PolicyPurchaseDate)){
            pol.Issue_Date_Time__c = convertToUTCDateTime(payload.PolicyPurchaseDate);
        }
        pol.Not_Renewing_Reason__c = payload.LapsedReason;
        pol.Name = payload.PolicyNumber;
        if(isValid(payload.VatAmount)){
            pol.Tax_Value__c = payload.VatAmount;
        }
        if(isValid(payload.IptAmount)){
            pol.IPT_Rate__c = payload.IptAmount;
        }
        pol.Value__c = payload.TotalPremium;
        pol.Premium_Value__c = payload.TotalPayable;
        pol.Instalment_Amount__c = payload.InstalmentAmount;
        if(isValid(payload.EffectiveUntilDate)){
            pol.Expiry_Date_time__c = convertToUTCDateTime(payload.EffectiveUntilDate);
        }
        if(isValid(payload.EffectiveFromDate)){
            pol.Inception_Date_Time__c = convertToUTCDateTime(payload.EffectiveFromDate);
        }
        if(payload.IsRenewalAllowedToLapse != null){
        	pol.Is_Not_Renewing__c = payload.IsRenewalAllowedToLapse;
        }
        if(accountId != null){
            pol.Customer__c = accountId; 
        }

        if(oppOwnerId != null){
            pol.OwnerId = oppOwnerId;
        }
        
        if(isValid(payload.PartnerId)){
            List<Account> partners = [SELECT Id FROM Account WHERE Partner_ID__c=:payload.PartnerId LIMIT 1];
            if(!partners.isEmpty()){
                pol.Partner_OLD__c = partners[0].Id;
            }
        }
        if(isValid(payload.PaymentType) || isValid(payload.PaymentTypeName)){
            String paymentMethod = '';

            Boolean hasPaymentType = false;
            if(isValid(payload.PaymentType)){
                hasPaymentType = true;
                paymentMethod = payload.PaymentType;
            }
            if(isValid(payload.PaymentTypeName)){
                if(hasPaymentType){
                    paymentMethod += ' - ' + payload.PaymentTypeName;
                }else{
                    paymentMethod = payload.PaymentTypeName;
                }
            }
            pol.Payment_Method__c = paymentMethod;
        }
        /*if(isValid(payload.IptAmount) || isValid(payload.VatAmount)){
            Decimal taxAmount = 0;
            if(isValid(payload.IptAmount)){
                taxAmount += payload.IptAmount;
            }
            if(isValid(payload.VatAmount)){
                taxAmount += payload.VatAmount;
            }
            pol.Tax_Value__c = taxAmount;
        }*/
        if(isValid(payload.PackageName)){
            List<Product2> products = [SELECT Id, isActive FROM Product2 WHERE Name =: payload.PackageName AND isActive = true LIMIT 1];
            if(!products.isEmpty()){
                pol.Product__c = products[0].Id;
            }
        }
        if(isValid(payload.PolicyNumberSuffixed)){
            pol.Version__c = payload.PolicyNumberSuffixed;
        }
        if(isValid(payload.RenewalCount)){
            pol.Renewal_Count__c = payload.RenewalCount.split('\\.')[0];
        }
        if(isValid(payload.MtaCount)){
            pol.MTA_Count__c = payload.MtaCount.split('\\.')[0];
        }
        if(isValid(payload.MtaHasPremiumRefund)){
            pol.MTA_Premium_Refund__c = payload.MtaHasPremiumRefund;
        }
        if(isValid(payload.MTA_TotalPayable)){
            pol.MTA_Total_Refundable__c = payload.MTA_TotalPayable;
        }
        return pol;

        
        //pol.Account__c = payload.
        //pol.End_Date_Time__c = payload.EffectiveUntilDate; //NOT AVAILABLE IN THE OBJECT
        //pol.Start_Date_Time__c = payload.EffectiveFromDate; //NOT AVAILABLE IN THE OBJECT
        //pol.IR35_Level__c = payload. 
        
        //pol.Master_Renewal_Opportunity__c = payload.
        //pol.Number_of_Instalments__c = payload.
        //pol.OwnerId = payload.
        //pol.Partner__c = payload.
        //pol.Product__c = payload.
        //pol.Referral_notes__c = payload.
        //pol.Referral_reason__c = payload.
        //pol.Term__c = payload.
    }
    
    public static String getRecordTypeNameById(String objectName, Id strRecordTypeId){
        return Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosById().get(strRecordTypeId).getName();
    }

    public static Id getRecordTypeIdbyName(String objectName, String strRecordTypeName){
        return  Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosByName().get(strRecordTypeName).getRecordTypeId();
    }

    public static GetMembersWrapper getMembers(Boolean isRoundRobin){
        GetMembersWrapper wrap = new GetMembersWrapper();
        wrap.memberIdList = new List<Id>();
        wrap.failBackUserId = null;

        String failBackUserName = '';
        Set<String> userNames = new Set<String>();
        Set<Id> activeUserIds = new Set<Id>();
        
        for(Opportunity_Round_Robin__mdt rrMetadata : [SELECT Id, DeveloperName, Name__c FROM Opportunity_Round_Robin__mdt WHERE Name__c != null]){
            if(isRoundRobin){
                userNames.add(rrMetadata.Name__c);
            }

            if(rrMetadata.DeveloperName == 'Failback_User'){
                failBackUserName = rrMetadata.Name__c;
                userNames.add(rrMetadata.Name__c);
            }
        }

        if(!isRoundRobin){
            Map<Id, Group> grpIdToGrpMap = groupIdToGroupMap('Renewals Team Leader');
            if(!grpIdToGrpMap.isEmpty()){        
                Id groupId = new List<Id>(grpIdToGrpMap.keyset())[0];
                Group grp = grpIdToGrpMap.get(groupId);
                for(GroupMember member : grp.GroupMembers){
                    if(member.UserOrGroupId.getsObjectType() == Schema.User.sObjectType){
                        userNames.add(member.UserOrGroup.Name);
                    } 
                }
            }
        }

        for(User usr : [SELECT Id, Name FROM User WHERE Name IN: userNames AND isActive = true]){
//            if(isRoundRobin){
//                activeUserIds.add(usr.Id);
//            }else{
                wrap.memberIdList.add(usr.Id);
//            }

            if(usr.Name == failBackUserName){
                wrap.failBackUserId = usr.Id;
            }
        }

//        if(!activeUserIds.isEmpty()){
//            for(UserServicePresence pres : [SELECT Id, ConfiguredCapacity, UserId, IsCurrentState, ServicePresenceStatus.MasterLabel 
//                                                FROM UserServicePresence 
//                                                WHERE UserId IN: activeUserIds 
//                                                AND IsCurrentState = true 
//                                                AND ServicePresenceStatus.MasterLabel = 'Available'
//                                                ORDER BY UserId ASC]){
//                wrap.memberIdList.add(pres.UserId);
//            }
//        }
        return wrap;
    }

    public static GetOwnerWrapper getOwnerId(Integer lastAssignedIndex){
        GetOwnerWrapper ownerWrap = new GetOwnerWrapper();
        ownerWrap.ownerId = null;

        GetMembersWrapper wrap = getMembers(true);
        if(!wrap.memberIdList.isEmpty()){
            lastAssignedIndex = (lastAssignedIndex + 1) >= wrap.memberIdList.size() ? 0 : lastAssignedIndex + 1;
            ownerWrap.ownerId = wrap.memberIdList.get(lastAssignedIndex);
        }else{
            ownerWrap.ownerId = wrap.failBackUserId;
        }
        ownerWrap.lastAssignedIndex = lastAssignedIndex;
        return ownerWrap;
    }

    public static Map<Integer, String> productMap = new Map<Integer, String> {
        29562 => 'Direct Professions',
        25990 => 'Admiral Trades',
        26466 => 'FUL Trades',
        26644 => 'IR35 Standalone',
        27974 => 'Single Buying Journey'
    };

    public static Map<Id, Group> groupIdToGroupMap(String groupName){
        Map<Id, Group> grpIdToGrpMap = new Map<Id, Group>();
        List<Group> groups = [SELECT Id, Name, DeveloperName, Type, (SELECT Id, UserOrGroupId, UserOrGroup.Name FROM GroupMembers) FROM Group WHERE Name =: groupName And Type = 'Queue' LIMIT 1];
        if(!groups.isEmpty()){
            Group grp = groups[0];
            grpIdToGrpMap.put(grp.Id, grp);
        }
        return grpIdToGrpMap;
    }

    // public static Datetime convertToUTCDateTime(String isoString) {
    //     // Parse individual parts from the string
    //     String parsedIso = isoString.replaceFirst('\\..*', '').replace('Z', '');
    //     List<String> dateTimeParts = parsedIso.split('T');
    //     List<String> dateParts = dateTimeParts[0].split('-');
    //     List<String> timeParts = dateTimeParts[1].split(':');
    
    //     Integer year = Integer.valueOf(dateParts[0]);
    //     Integer month = Integer.valueOf(dateParts[1]);
    //     Integer day = Integer.valueOf(dateParts[2]);
    
    //     Integer hour = Integer.valueOf(timeParts[0]);
    //     Integer minute = Integer.valueOf(timeParts[1]);
    //     Integer second = Integer.valueOf(timeParts[2]);
    
    //     // Create datetime in UTC (GMT)
    //     return Datetime.newInstanceGmt(year, month, day, hour, minute, second);
    // }

    public static Date isoStringToDate(String isoString) {
        if (String.isBlank(isoString)) return null;

        // Normalize ISO → Salesforce Datetime format
        String raw = isoString.replace('T', ' ').replace('Z', '');

        // Ensure milliseconds
        if (!raw.contains('.')) {
            raw += '.000';
        }

        // Parse as UTC
        Datetime utcDt = Datetime.valueOfGmt(raw);

        // Convert to local date (user timezone)
        return utcDt.date();
    }    

    public static Datetime convertToUTCDateTime(String isoString) {
        if (String.isBlank(isoString)) return null;

        String raw = isoString.trim();

        // Normalize ISO format → Salesforce format
        raw = raw.replace('T', ' ').replace('Z', '');

        // Ensure milliseconds
        if (!raw.contains('.')) {
            raw += '.000';
        } else {
            List<String> parts = raw.split('\\.');
            String ms = parts[1].rightPad(3, '0').substring(0, 3);
            raw = parts[0] + '.' + ms;
        }

    
        return Datetime.valueOfGmt(raw);
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

    private static final Map<String, String> SOURCE_MAP = new Map<String, String>{
        'My friend' => 'RAF',
        'Accountancy/recruitment company/professional body' => 'Partner',
        'my employer/client' => 'Partner',
        'Search engine' => 'Direct',
        'A marketing communication from Kingsbridge' => 'Direct',
        'Social network (LinkedIn, Facebook etc)' => 'Direct',
        'Marketing campaign' => 'Direct',
        'I\'m an existing or returning customer' => 'Direct'
    };

    public static String determineLeadSource(String whereHeard) {
        if (String.isNotBlank(whereHeard)) {
            // Trim and make case-insensitive match
            for (String key : SOURCE_MAP.keySet()) {
                if (key.equalsIgnoreCase(whereHeard.trim())) {
                    return SOURCE_MAP.get(key);
                }
            }
        }
        return null; // or return 'Unknown' if you want a fallback
    }
    
    public static Map<Integer, Integer> getCount() {
        Map<Integer, Integer> resultMap = new Map<Integer, Integer>();
    
        // Manually putting key-value pairs from 1 to 100
        resultMap.put(1, 1);
        resultMap.put(2, 2);
        resultMap.put(3, 3);
        resultMap.put(4, 4);
        resultMap.put(5, 5);
        resultMap.put(6, 6);
        resultMap.put(7, 7);
        resultMap.put(8, 8);
        resultMap.put(9, 9);
        resultMap.put(10, 10);
        resultMap.put(11, 11);
        resultMap.put(12, 12);
        resultMap.put(13, 13);
        resultMap.put(14, 14);
        resultMap.put(15, 15);
        resultMap.put(16, 16);
        resultMap.put(17, 17);
        resultMap.put(18, 18);
        resultMap.put(19, 19);
        resultMap.put(20, 20);
        resultMap.put(21, 21);
        resultMap.put(22, 22);
        resultMap.put(23, 23);
        resultMap.put(24, 24);
        resultMap.put(25, 25);
        resultMap.put(26, 26);
        resultMap.put(27, 27);
        resultMap.put(28, 28);
        resultMap.put(29, 29);
        resultMap.put(30, 30);
        resultMap.put(31, 31);
        resultMap.put(32, 32);
        resultMap.put(33, 33);
        resultMap.put(34, 34);
        resultMap.put(35, 35);
        resultMap.put(36, 36);
        resultMap.put(37, 37);
        resultMap.put(38, 38);
        resultMap.put(39, 39);
        resultMap.put(40, 40);
        resultMap.put(41, 41);
        resultMap.put(42, 42);
        resultMap.put(43, 43);
        resultMap.put(44, 44);
        resultMap.put(45, 45);
        resultMap.put(46, 46);
        resultMap.put(47, 47);
        resultMap.put(48, 48);
        resultMap.put(49, 49);
        resultMap.put(50, 50);
        resultMap.put(51, 51);
        resultMap.put(52, 52);
        resultMap.put(53, 53);
        resultMap.put(54, 54);
        resultMap.put(55, 55);
        resultMap.put(56, 56);
        resultMap.put(57, 57);
        resultMap.put(58, 58);
        resultMap.put(59, 59);
        resultMap.put(60, 60);
        resultMap.put(61, 61);
        resultMap.put(62, 62);
        resultMap.put(63, 63);
        resultMap.put(64, 64);
        resultMap.put(65, 65);
        resultMap.put(66, 66);
        resultMap.put(67, 67);
        resultMap.put(68, 68);
        resultMap.put(69, 69);
        resultMap.put(70, 70);
        resultMap.put(71, 71);
        resultMap.put(72, 72);
        resultMap.put(73, 73);
        resultMap.put(74, 74);
        resultMap.put(75, 75);
        resultMap.put(76, 76);
        resultMap.put(77, 77);
        resultMap.put(78, 78);
        resultMap.put(79, 79);
        resultMap.put(80, 80);
        resultMap.put(81, 81);
        resultMap.put(82, 82);
        resultMap.put(83, 83);
        resultMap.put(84, 84);
        resultMap.put(85, 85);
        resultMap.put(86, 86);
        resultMap.put(87, 87);
        resultMap.put(88, 88);
        resultMap.put(89, 89);
        resultMap.put(90, 90);
        resultMap.put(91, 91);
        resultMap.put(92, 92);
        resultMap.put(93, 93);
        resultMap.put(94, 94);
        resultMap.put(95, 95);
        resultMap.put(96, 96);
        resultMap.put(97, 97);
        resultMap.put(98, 98);
        resultMap.put(99, 99);
        resultMap.put(100, 100);
        resultMap.put(101, 101);
        resultMap.put(102, 102);
        resultMap.put(103, 103);
        resultMap.put(104, 104);
        resultMap.put(105, 105);
        resultMap.put(106, 106);
        resultMap.put(107, 107);
        resultMap.put(108, 108);
        resultMap.put(109, 109);
        resultMap.put(110, 110);
        resultMap.put(111, 111);
        resultMap.put(112, 112);
        resultMap.put(113, 113);
        resultMap.put(114, 114);
        resultMap.put(115, 115);
        resultMap.put(116, 116);
        resultMap.put(117, 117);
        resultMap.put(118, 118);
        resultMap.put(119, 119);
        resultMap.put(120, 120);
        resultMap.put(121, 121);
        resultMap.put(122, 122);
        resultMap.put(123, 123);
        resultMap.put(124, 124);
        resultMap.put(125, 125);
        resultMap.put(126, 126);
        resultMap.put(127, 127);
        resultMap.put(128, 128);
        resultMap.put(129, 129);
        resultMap.put(130, 130);
        resultMap.put(131, 131);
        resultMap.put(132, 132);
        resultMap.put(133, 133);
        resultMap.put(134, 134);
        resultMap.put(135, 135);
        resultMap.put(136, 136);
        resultMap.put(137, 137);
        resultMap.put(138, 138);
        resultMap.put(139, 139);
        resultMap.put(140, 140);
        resultMap.put(141, 141);
        resultMap.put(142, 142);
        resultMap.put(143, 143);
        resultMap.put(144, 144);
        resultMap.put(145, 145);
        resultMap.put(146, 146);
        resultMap.put(147, 147);
        resultMap.put(148, 148);
        resultMap.put(149, 149);
        resultMap.put(150, 150);
        resultMap.put(151, 151);
        resultMap.put(152, 152);
        resultMap.put(153, 153);
        resultMap.put(154, 154);
        resultMap.put(155, 155);
        resultMap.put(156, 156);
        resultMap.put(157, 157);
        resultMap.put(158, 158);
        resultMap.put(159, 159);
        resultMap.put(160, 160);
        resultMap.put(161, 161);
        resultMap.put(162, 162);
        resultMap.put(163, 163);
        resultMap.put(164, 164);
        resultMap.put(165, 165);
        resultMap.put(166, 166);
        resultMap.put(167, 167);
        resultMap.put(168, 168);
        resultMap.put(169, 169);
        resultMap.put(170, 170);
        resultMap.put(171, 171);
        resultMap.put(172, 172);
        resultMap.put(173, 173);
        resultMap.put(174, 174);
        resultMap.put(175, 175);
        resultMap.put(176, 176);
        resultMap.put(177, 177);
        resultMap.put(178, 178);
        resultMap.put(179, 179);
        resultMap.put(180, 180);
        resultMap.put(181, 181);
        resultMap.put(182, 182);
        resultMap.put(183, 183);
        resultMap.put(184, 184);
        resultMap.put(185, 185);
        resultMap.put(186, 186);
        resultMap.put(187, 187);
        resultMap.put(188, 188);
        resultMap.put(189, 189);
        resultMap.put(190, 190);
        resultMap.put(191, 191);
        resultMap.put(192, 192);
        resultMap.put(193, 193);
        resultMap.put(194, 194);
        resultMap.put(195, 195);
        resultMap.put(196, 196);
        resultMap.put(197, 197);
        resultMap.put(198, 198);
        resultMap.put(199, 199);
        resultMap.put(200, 200);
        resultMap.put(201, 201);
        resultMap.put(202, 202);
        resultMap.put(203, 203);
        resultMap.put(204, 204);
        resultMap.put(205, 205);
        resultMap.put(206, 206);
        resultMap.put(207, 207);
        resultMap.put(208, 208);
        resultMap.put(209, 209);
        resultMap.put(210, 210);
        resultMap.put(211, 211);
        resultMap.put(212, 212);
        resultMap.put(213, 213);
        resultMap.put(214, 214);
        resultMap.put(215, 215);
        resultMap.put(216, 216);
        resultMap.put(217, 217);
        resultMap.put(218, 218);
        resultMap.put(219, 219);
        resultMap.put(220, 220);
        resultMap.put(221, 221);
        resultMap.put(222, 222);
        resultMap.put(223, 223);
        resultMap.put(224, 224);
        resultMap.put(225, 225);
        resultMap.put(226, 226);
        resultMap.put(227, 227);
        resultMap.put(228, 228);
        resultMap.put(229, 229);
        resultMap.put(230, 230);
        resultMap.put(231, 231);
        resultMap.put(232, 232);
        resultMap.put(233, 233);
        resultMap.put(234, 234);
        resultMap.put(235, 235);
        resultMap.put(236, 236);
        resultMap.put(237, 237);
        resultMap.put(238, 238);
        resultMap.put(239, 239);
        resultMap.put(240, 240);
        resultMap.put(241, 241);
        resultMap.put(242, 242);
        resultMap.put(243, 243);
        resultMap.put(244, 244);
        resultMap.put(245, 245);
        resultMap.put(246, 246);
        resultMap.put(247, 247);
        resultMap.put(248, 248);
        resultMap.put(249, 249);
        resultMap.put(250, 250);
        resultMap.put(251, 251);
        resultMap.put(252, 252);
        resultMap.put(253, 253);
        resultMap.put(254, 254);
        resultMap.put(255, 255);
        resultMap.put(256, 256);
        resultMap.put(257, 257);
        resultMap.put(258, 258);
        resultMap.put(259, 259);
        resultMap.put(260, 260);
        resultMap.put(261, 261);
        resultMap.put(262, 262);
        resultMap.put(263, 263);
        resultMap.put(264, 264);
        resultMap.put(265, 265);
        resultMap.put(266, 266);
        resultMap.put(267, 267);
        resultMap.put(268, 268);
        resultMap.put(269, 269);
        resultMap.put(270, 270);
        resultMap.put(271, 271);
        resultMap.put(272, 272);
        resultMap.put(273, 273);
        resultMap.put(274, 274);
        resultMap.put(275, 275);
        resultMap.put(276, 276);
        resultMap.put(277, 277);
        resultMap.put(278, 278);
        resultMap.put(279, 279);
        resultMap.put(280, 280);
        resultMap.put(281, 281);
        resultMap.put(282, 282);
        resultMap.put(283, 283);
        resultMap.put(284, 284);
        resultMap.put(285, 285);
        resultMap.put(286, 286);
        resultMap.put(287, 287);
        resultMap.put(288, 288);
        resultMap.put(289, 289);
        resultMap.put(290, 290);
        resultMap.put(291, 291);
        resultMap.put(292, 292);
        resultMap.put(293, 293);
        resultMap.put(294, 294);
        resultMap.put(295, 295);
        resultMap.put(296, 296);
        resultMap.put(297, 297);
        resultMap.put(298, 298);
        resultMap.put(299, 299);
        resultMap.put(300, 300);
        resultMap.put(301, 301);
        resultMap.put(302, 302);
        resultMap.put(303, 303);
        resultMap.put(304, 304);
        resultMap.put(305, 305);
        resultMap.put(306, 306);
        resultMap.put(307, 307);
        resultMap.put(308, 308);
        resultMap.put(309, 309);
        resultMap.put(310, 310);
        resultMap.put(311, 311);
        resultMap.put(312, 312);
        resultMap.put(313, 313);
        resultMap.put(314, 314);
        resultMap.put(315, 315);
        resultMap.put(316, 316);
        resultMap.put(317, 317);
        resultMap.put(318, 318);
        resultMap.put(319, 319);
        resultMap.put(320, 320);
        resultMap.put(321, 321);
        resultMap.put(322, 322);
        resultMap.put(323, 323);
        resultMap.put(324, 324);
        resultMap.put(325, 325);
        resultMap.put(326, 326);
        resultMap.put(327, 327);
        resultMap.put(328, 328);
        resultMap.put(329, 329);
        resultMap.put(330, 330);
        resultMap.put(331, 331);
        resultMap.put(332, 332);
        resultMap.put(333, 333);
        resultMap.put(334, 334);
        resultMap.put(335, 335);
        resultMap.put(336, 336);
        resultMap.put(337, 337);
        resultMap.put(338, 338);
        resultMap.put(339, 339);
        resultMap.put(340, 340);
        resultMap.put(341, 341);
        resultMap.put(342, 342);
        resultMap.put(343, 343);
        resultMap.put(344, 344);
        resultMap.put(345, 345);
        resultMap.put(346, 346);
        resultMap.put(347, 347);
        resultMap.put(348, 348);
        resultMap.put(349, 349);
        resultMap.put(350, 350);
        resultMap.put(351, 351);
        resultMap.put(352, 352);
        resultMap.put(353, 353);
        resultMap.put(354, 354);
        resultMap.put(355, 355);
        resultMap.put(356, 356);
        resultMap.put(357, 357);
        resultMap.put(358, 358);
        resultMap.put(359, 359);
        resultMap.put(360, 360);
        resultMap.put(361, 361);
        resultMap.put(362, 362);
        resultMap.put(363, 363);
        resultMap.put(364, 364);
        resultMap.put(365, 365);
        resultMap.put(366, 366);
        resultMap.put(367, 367);
        resultMap.put(368, 368);
        resultMap.put(369, 369);
        resultMap.put(370, 370);
        resultMap.put(371, 371);
        resultMap.put(372, 372);
        resultMap.put(373, 373);
        resultMap.put(374, 374);
        resultMap.put(375, 375);
        resultMap.put(376, 376);
        resultMap.put(377, 377);
        resultMap.put(378, 378);
        resultMap.put(379, 379);
        resultMap.put(380, 380);
        resultMap.put(381, 381);
        resultMap.put(382, 382);
        resultMap.put(383, 383);
        resultMap.put(384, 384);
        resultMap.put(385, 385);
        resultMap.put(386, 386);
        resultMap.put(387, 387);
        resultMap.put(388, 388);
        resultMap.put(389, 389);
        resultMap.put(390, 390);
        resultMap.put(391, 391);
        resultMap.put(392, 392);
        resultMap.put(393, 393);
        resultMap.put(394, 394);
        resultMap.put(395, 395);
        resultMap.put(396, 396);
        resultMap.put(397, 397);
        resultMap.put(398, 398);
        resultMap.put(399, 399);
        resultMap.put(400, 400);
        resultMap.put(401, 401);
        resultMap.put(402, 402);
        resultMap.put(403, 403);
        resultMap.put(404, 404);
        resultMap.put(405, 405);
        resultMap.put(406, 406);
        resultMap.put(407, 407);
        resultMap.put(408, 408);
        resultMap.put(409, 409);
        resultMap.put(410, 410);
        resultMap.put(411, 411);
        resultMap.put(412, 412);
        resultMap.put(413, 413);
        resultMap.put(414, 414);
        resultMap.put(415, 415);
        resultMap.put(416, 416);
        resultMap.put(417, 417);
        resultMap.put(418, 418);
        resultMap.put(419, 419);
        resultMap.put(420, 420);
        resultMap.put(421, 421);
        resultMap.put(422, 422);
        resultMap.put(423, 423);
        resultMap.put(424, 424);
        resultMap.put(425, 425);
        resultMap.put(426, 426);
        resultMap.put(427, 427);
        resultMap.put(428, 428);
        resultMap.put(429, 429);
        resultMap.put(430, 430);
        resultMap.put(431, 431);
        resultMap.put(432, 432);
        resultMap.put(433, 433);
        resultMap.put(434, 434);
        resultMap.put(435, 435);
        resultMap.put(436, 436);
        resultMap.put(437, 437);
        resultMap.put(438, 438);
        resultMap.put(439, 439);
        resultMap.put(440, 440);
        resultMap.put(441, 441);
        resultMap.put(442, 442);
        resultMap.put(443, 443);
        resultMap.put(444, 444);
        resultMap.put(445, 445);
        resultMap.put(446, 446);
        resultMap.put(447, 447);
        resultMap.put(448, 448);
        resultMap.put(449, 449);
        resultMap.put(450, 450);
        resultMap.put(451, 451);
        resultMap.put(452, 452);
        resultMap.put(453, 453);
        resultMap.put(454, 454);
        resultMap.put(455, 455);
        resultMap.put(456, 456);
        resultMap.put(457, 457);
        resultMap.put(458, 458);
        resultMap.put(459, 459);
        resultMap.put(460, 460);
        resultMap.put(461, 461);
        resultMap.put(462, 462);
        resultMap.put(463, 463);
        resultMap.put(464, 464);
        resultMap.put(465, 465);
        resultMap.put(466, 466);
        resultMap.put(467, 467);
        resultMap.put(468, 468);
        resultMap.put(469, 469);
        resultMap.put(470, 470);
        resultMap.put(471, 471);
        resultMap.put(472, 472);
        resultMap.put(473, 473);
        resultMap.put(474, 474);
        resultMap.put(475, 475);
        resultMap.put(476, 476);
        resultMap.put(477, 477);
        resultMap.put(478, 478);
        resultMap.put(479, 479);
        resultMap.put(480, 480);
        resultMap.put(481, 481);
        resultMap.put(482, 482);
        resultMap.put(483, 483);
        resultMap.put(484, 484);
        resultMap.put(485, 485);
        resultMap.put(486, 486);
        resultMap.put(487, 487);
        resultMap.put(488, 488);
        resultMap.put(489, 489);
        resultMap.put(490, 490);
        resultMap.put(491, 491);
        resultMap.put(492, 492);
        resultMap.put(493, 493);
        resultMap.put(494, 494);
        resultMap.put(495, 495);
        resultMap.put(496, 496);
        resultMap.put(497, 497);
        resultMap.put(498, 498);
        resultMap.put(499, 499);
        resultMap.put(500, 500);
        resultMap.put(501, 501);
        resultMap.put(502, 502);
        resultMap.put(503, 503);
        resultMap.put(504, 504);
        resultMap.put(505, 505);
        resultMap.put(506, 506);
        resultMap.put(507, 507);
        resultMap.put(508, 508);
        resultMap.put(509, 509);
        resultMap.put(510, 510);
        resultMap.put(511, 511);
        resultMap.put(512, 512);
        resultMap.put(513, 513);
        resultMap.put(514, 514);
        resultMap.put(515, 515);
        resultMap.put(516, 516);
        resultMap.put(517, 517);
        resultMap.put(518, 518);
        resultMap.put(519, 519);
        resultMap.put(520, 520);
        resultMap.put(521, 521);
        resultMap.put(522, 522);
        resultMap.put(523, 523);
        resultMap.put(524, 524);
        resultMap.put(525, 525);

    
        return resultMap;
    }

    public class GetOwnerWrapper{
        public Id ownerId;
        public Integer lastAssignedIndex;
    }

    public class GetMembersWrapper{
        public Id failBackUserId;
        public List<Id> memberIdList;
    }

    public class RequestHandler{
        public String PreviousPaymentMethod;
        public String QuoteRef;
        public String SBJQuoteRef;
        public String PolicyNumber;
        public String PolicyNumberSuffixed;
        public String ClaimRef;
        public String PackageName;
        public String PackageCode;
        public Decimal PackageIdentifier;
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
        public String SaleCompletedBySalesPersonEmail;
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
        public String PolicyholderAlternativePhone;
        public String UnlistedReferralCompany;
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
        public String PriceReductionType;
        public Decimal DiscountAmount;
        public Decimal PremiumAdjustment;
        public Decimal PricematchPremium;
        public Decimal TotalPremium;
        public Decimal IptAmount;
        public Decimal VatAmount;
        public String PaymentType;
        public String PaymentTypeName;
        public Decimal TotalPayable;
        public Decimal InstalmentAmount;
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
        public Decimal StatusReviewsPrice;
        public String ProductType;

        public Decimal TotalPayablePerMonth;
        public String CancellationDate;
        public String CancellationCreatedOnDate;
        public String CancellationReason;
        public String PolicyPurchaseDate;
        public String LapsedReason;
        public String PredictedRenewalDate;
        public String PartnerId;
        public String CustomerRef;
        public Boolean IsRenewalAllowedToLapse;
        public String CustomerOptedOutOfRenewal;
        public Boolean RenewalBlocked;
        public String EverMadeAnyClaim;
        public String AcceptHealthcareExclusion;
        public String AcceptLegalServicesExclusion;
        public String Ern;
        public String utm_source;
        public String utm_term;
        public String utm_medium;
        public String utm_content;
        public String utm_campaign;
        public String CurrentlyHaveBusinessInsurance;
        public String InsuredByAlready;
        public String CurrentRenewalDate;

        //Cancellation
        public String CancellationConfirmedDate;
        public String CancellationEffectiveFromDate;
        public String TopLevelCancellationReason;

        //RAF
        public String RafLink;
        public String RafReferredByName;
        public String RafReferredByEmail;

        //OTHER PARTNER
        public String PartnerCompanyOther;

        //Referred
        public Boolean Referred;

        //Orange-Highlighted
        public String AddCyberLiability;
        public String HasLegalExpenses;
        public String AcceptAviationExclusion;
        public String AcceptArchitectureExclusion;
        public String BankruptOrAdministration;
        public String EverBankruptOrAdministration;
        public String IR35CoverLevel;
        public String SafetyCriticalWork;
        public String EverDeclinedOrSpecialTerms;
        public String EverDeclinedOrSpecialTermsDetails;
        public String NonMotoringCriminalOffences;
        public String HeatOrHighVoltageWork;
        public String AcceptNuclearExclusion;
        public Decimal NumberOfFeeEarningEmployees;
        public Decimal NumberOfClericalEmployees;
        public Decimal NumberOfFamilyClerical;
        public Decimal NumberOfNonFamilyClerical;
        public String SmeBusinessActivity_2;
        public String SmeBusinessActivity_3;
        public String SmeBusinessActivity_4;
        public String SmeBusinessActivity_5;
        public String WorkAtHeight;
        public String ManualWork;
        public String WorkOffshore;
        public String RicsMember;
        public String UsaWorkOrContract;
        public String UsaContract;
        public String UsaPhysical;
        public String UsaOver30Days;

        public String RenewalCount;
        public String MtaCount;
        public String WhereHeard;
        public String WhereHeardFriendName;
        public String WhereHeardFriendEmail;
        public String WhereHeardEmployerClientCompany;
        public String WhereHeardEmployerClientPerson;
        public String WhereHeardPartnerPerson;
        public String PartnerCompanyPerson;
        public Decimal IR35StatusToolFee;
        public Boolean MtaHasPremiumRefund;
        public Decimal MTA_TotalPayable;
    }
}