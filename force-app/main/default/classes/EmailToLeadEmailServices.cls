global class EmailToLeadEmailServices implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, Messaging.InboundEnvelope env){
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        String myPlainText= '';
    
        myPlainText = email.plainTextBody;
        
        system.debug('@@@ email.plainTextBody = ' + email.plainTextBody);
        system.debug('@@@ email.fromAddress = ' + email.fromAddress);   

        Lead leadToCreate = new Lead();
        leadToCreate.LeadSource = 'refer@kingsbridge.co.uk';
        leadToCreate.Referred_By__c = email.fromName;
        leadToCreate.Referred_By_Email__c = email.fromAddress;
        leadToCreate.Description = myPlainText;
        
        if(myPlainText != null && myPlainText != ''){
            leadToCreate.FirstName = (String.IsNotBlank(myPlainText.subStringBetween('First Name:', 'Last Name:'))) ? myPlainText.subStringBetween('First Name:', 'Last Name:').trim() : myPlainText.subStringBetween('First Name:', 'Last Name:');
            leadToCreate.LastName = (String.IsNotBlank(myPlainText.subStringBetween('Last Name:', 'Email Address:'))) ? myPlainText.subStringBetween('Last Name:', 'Email Address:').trim() : myPlainText.subStringBetween('Last Name:', 'Email Address:');

            String emailStr = myPlainText.subStringBetween('Email Address:', 'Phone Number:').trim();

            Integer startInt = emailStr.indexOf('<');
            Integer endInt = emailStr.indexOf('>');

            String finalEmailStr = '';
            if (startInt != -1 && endInt != -1 && startInt < endInt) {
                String before = emailStr.substring(0, startInt);
                String after = emailStr.substring(endInt + 1);
                finalEmailStr = before + after;
                System.debug('***finalEmailStr = ' + finalEmailStr);
            } else {
                System.debug('***finalEmailStr no trim = ' + finalEmailStr);
            }

            leadToCreate.Email = finalEmailStr;
            leadToCreate.Phone = myPlainText.subStringBetween('Phone Number:', 'Kind regards').trim();
        }

        String referrerEmail = email.fromAddress;
        String fromDomain = email.fromAddress.substringAfter('@');

        List<Account> findAccount = [SELECT Id, Partner_ID__c FROM Account WHERE Email_Domain__c =: fromDomain AND RecordType.Name = 'Partner Accounts' ORDER BY CreatedDate ASC];
        if(!findAccount.isEmpty()){
            leadToCreate.Partner_ID__c = findAccount.get(0).Partner_ID__c;
            leadToCreate.Partner__c = findAccount.get(0).Id;
        }
        else{
            List<Contact> findContact = [SELECT Id, AccountId, Account.Partner_ID__c FROM Contact WHERE Email LIKE: fromDomain AND AccountId != null];
            if(!findContact.isEmpty()){
                leadToCreate.Partner_ID__c = findContact.get(0).Account.Partner_ID__c;
                leadToCreate.Partner__c = findContact.get(0).AccountId;
            }
            else{
                List<Account> directAccount = [SELECT Id, Partner_ID__c FROM Account WHERE RecordType.Name = 'Partner Accounts' AND Partner_ID__c = 'KPS' LIMIT 1];
                if(!directAccount.isEmpty()){
                    leadToCreate.Partner_ID__c = directAccount.get(0).Partner_ID__c;
                    leadToCreate.Partner__c = directAccount.get(0).Id;
                }
            }
        }
        insert leadToCreate;

        result.success = true;
        return result;
    }
}