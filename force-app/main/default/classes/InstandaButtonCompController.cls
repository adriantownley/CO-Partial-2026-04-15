public without sharing class InstandaButtonCompController {
    
    @AuraEnabled
    public static DataWrapper generateURL(Id recordId, String objectAPIName){
        try {   
            InstandaApi__c insApi = InstandaApi__c.getOrgDefaults();

            DataWrapper dataWrapp = new DataWrapper();
            dataWrapp.generatedURL =  'https://' + insApi.base_url__c;
            dataWrapp.dataToCopy = '';

            List<String> urlData = new List<String>();

            system.debug('***recordId = ' + recordId);
            system.debug('***objectAPIName = ' + objectAPIName);

            if(objectAPIName == 'Lead'){
                Lead leadRecord = [SELECT Id, Salutation, FirstName, LastName, Email, Phone, Occupation__c, Product_Code__c, Product_Type__c FROM Lead WHERE Id =: recordId];

                if(leadRecord.Product_Type__c.contains('IR35 Protect Standalone')){
                    dataWrapp.generatedURL += '/Public/PreQuoteQuestions'; 
                } else {
                    dataWrapp.generatedURL += '/Public/QuickQuoteQuestions'; 
                }

                if(leadRecord.Product_Code__c != null) {
                    if((leadRecord.Product_Type__c).contains('Admiral Trades') || (leadRecord.Product_Type__c).contains('FUL Trades')){
                        urlData.add('PackageId=27974');
                    }else{
                        urlData.add('PackageId=' + leadRecord.Product_Code__c);
                    }
                }else{
                    urlData.add('PackageId=' + leadRecord.Product_Code__c);
                }

                if(leadRecord.Salutation != null) urlData.add('Param_PolicyholderTitle=' + leadRecord.Salutation);
                if(leadRecord.FirstName != null) urlData.add('Param_PolicyholderFirstName=' + leadRecord.FirstName);
                if(leadRecord.LastName != null) urlData.add('Param_PolicyholderLastName=' + leadRecord.LastName);
                if(leadRecord.Email != null) urlData.add('Param_PolicyholderEmail=' + leadRecord.Email);
                if(leadRecord.Phone != null) urlData.add('Param_PolicyholderPhone=' + leadRecord.Phone);
                if(leadRecord.Occupation__c != null) urlData.add('Param_BusinessActivity=' + leadRecord.Occupation__c); 

                // if(leadRecord.Product_Type__c != null){
                //     if(leadRecord.Product_Type__c == 'IR35 Protect Standalone'){
                //         urlData.add('PackageId=' + insApi.Package_Id_1_only_IR35__c);
                //     }
                //     else if(leadRecord.Product_Type__c.contains(';')){
                //         urlData.add('PackageId=' + insApi.Package_Id_2__c);
                //     }
                // }

                // if(leadRecord.Product_Code__c != null) urlData.add('PackageId=' + leadRecord.Product_Code__c); 
            } else if(objectAPIName == 'Account'){
                Account accountRecord = [SELECT Id, PersonMailingPostalCode, PersonEmail, INSTANDA_Quote_ID__c FROM Account WHERE Id =: recordId];
                dataWrapp.generatedURL += '/Public/AgentRetrieveQuoteCrossPackage'; 

                if(accountRecord.INSTANDA_Quote_ID__c != null) urlData.add('QuoteRef=' + accountRecord.INSTANDA_Quote_ID__c);
                if(accountRecord.PersonMailingPostalCode != null) urlData.add('PolicyholderPostcode=' + accountRecord.PersonMailingPostalCode);
                if(accountRecord.PersonEmail != null) urlData.add('PolicyholderEmail=' + accountRecord.PersonEmail);

                dataWrapp.dataToCopy = accountRecord.PersonMailingPostalCode;
            } else if(objectAPIName == 'Opportunity'){
                Opportunity oppRecord = [SELECT Id, Name, INSTANDA_Quote_ID__c, Account.BillingPostalCode, Account.Account_Email__c FROM Opportunity WHERE Id =: recordId];
                dataWrapp.generatedURL += '/Public/AgentRetrieveQuoteCrossPackage'; 

                if(oppRecord.INSTANDA_Quote_ID__c != null) urlData.add('QuoteRef=' + oppRecord.INSTANDA_Quote_ID__c);
                if(oppRecord.Account.BillingPostalCode != null) urlData.add('PolicyholderPostcode=' + oppRecord.Account.BillingPostalCode);
                if(oppRecord.Account.Account_Email__c != null) urlData.add('PolicyholderEmail=' + oppRecord.Account.Account_Email__c);

                dataWrapp.dataToCopy = oppRecord.INSTANDA_Quote_ID__c;
            } else if(objectAPIName == 'Case'){
                Case caseRecord = [SELECT Id, Opportunity__r.INSTANDA_Quote_ID__c, Account.PersonMailingPostalCode, Account.PersonEmail FROM Case WHERE Id =: recordId];
                dataWrapp.generatedURL += '/Public/AgentRetrieveQuoteCrossPackage'; 

                if(caseRecord.Opportunity__r.INSTANDA_Quote_ID__c != null) urlData.add('QuoteRef=' + caseRecord.Opportunity__r.INSTANDA_Quote_ID__c);
                if(caseRecord.Account.PersonMailingPostalCode != null) urlData.add('PolicyholderPostcode=' + caseRecord.Account.PersonMailingPostalCode);
                if(caseRecord.Account.PersonEmail != null) urlData.add('PolicyholderEmail=' + caseRecord.Account.PersonEmail);

                dataWrapp.dataToCopy = (caseRecord.Opportunity__r.INSTANDA_Quote_ID__c != null) ? caseRecord.Opportunity__r.INSTANDA_Quote_ID__c : caseRecord.Account.PersonMailingPostalCode;
            } else if(objectAPIName == 'Policy__c'){
                Policy__c policyRecord = [SELECT Id, INSTANDA_Quote_ID__c, Customer__r.PersonMailingPostalCode, Customer__r.PersonEmail FROM Policy__c WHERE Id =: recordId];
                dataWrapp.generatedURL += '/Public/AgentRetrieveQuoteCrossPackage'; 

                if(policyRecord.INSTANDA_Quote_ID__c != null) urlData.add('QuoteRef=' + policyRecord.INSTANDA_Quote_ID__c);
                if(policyRecord.Customer__r.PersonMailingPostalCode != null) urlData.add('PolicyholderPostcode=' + policyRecord.Customer__r.PersonMailingPostalCode);
                if(policyRecord.Customer__r.PersonEmail != null) urlData.add('PolicyholderEmail=' + policyRecord.Customer__r.PersonEmail);

                dataWrapp.dataToCopy = policyRecord.INSTANDA_Quote_ID__c;
            }
            
            system.debug('***urlData = ' + urlData);

            if(!urlData.isEmpty()){
                dataWrapp.generatedURL += '?' + String.join(urlData, '&');
            }

            system.debug('***dataWrapp.generatedURL = ' + dataWrapp.generatedURL);
            return dataWrapp;
        } catch (Exception e) {
            system.debug('***Exception = ' + e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static DataWrapper generateURLLead2(Id recordId){
        try {
            InstandaApi__c insApi = InstandaApi__c.getOrgDefaults();

            DataWrapper dataWrapp = new DataWrapper();
            dataWrapp.generatedURL =  'https://' + insApi.base_url__c;
            dataWrapp.dataToCopy = '';

            Lead leadRecord = [SELECT Id, Email, INSTANDA_Quote_ID__c FROM Lead WHERE Id =: recordId];
            dataWrapp.generatedURL += '/Public/AgentRetrieveQuoteCrossPackage?quoteRef=' + leadRecord.INSTANDA_Quote_ID__c;
            dataWrapp.dataToCopy = leadRecord.Email;
            return dataWrapp;   
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class DataWrapper{
        @AuraEnabled public String generatedURL;
        @AuraEnabled public String dataToCopy;
    }
}