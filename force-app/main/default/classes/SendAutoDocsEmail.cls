/*public class SendAutoDocsEmail {
    @future   
    public static void sendPurchaseEmail(String policyNo){
        // 1. Fetch the Policy and its Related Files
        Policy__c policy = [SELECT Id, Name,Account_Partner_ID__c FROM Policy__c WHERE Name =: policyNo Limit 1];//'TST-KCI-1803BB' LIMIT 1];//'a1VAd00000615YT'
        
        //1. Fetch the Partner Account related to policy
        if (!Test.isRunningTest()) { // added for test 22:30
        Account partnerAccount =[SELECT Id, Name,RecordType.Name,Partner_ID__c From Account Where RecordType.Name='Partner Accounts' And Partner_ID__c=:policy.Account_Partner_ID__c];
        
        // 3. Fetch the Contact
        Contact targetContact = [SELECT Id,LastName, Email FROM Contact WHERE LastName='AutoDocsEmail' And Account.Name =: partnerAccount.Name LIMIT 1];//'lukasz.zawieja@gmail.com' LIMIT 1];
        
        // Query ContentDocumentLinks to find files attached to the Policy
        List<ContentDocumentLink> links = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :policy.Id];
        
        List<Id> docIds = new List<Id>();
        for (ContentDocumentLink cdl : links) {
            docIds.add(cdl.ContentDocumentId);
        }

        // Get the latest Version IDs for those documents
        List<ContentVersion> versions = [SELECT Id FROM ContentVersion WHERE ContentDocumentId IN :docIds AND IsLatest = true];
        List<Id> versionIds = new List<Id>();
        for (ContentVersion cv : versions) {
            versionIds.add(cv.Id);
        }

        // 3. Get the Email Template
        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Partner_Policy_Purchase_VF' LIMIT 1];

        // 4. Construct the Email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        // Set the target: Who receives it and what record provides the merge data
        mail.setTargetObjectId(targetContact.Id);
        mail.setWhatId(policy.Id); // This allows the VF template to use the Policy fields
        mail.setTemplateId(template.Id);
        //mail.toAddresses = new String[]{'lukasz.zawieja@kingsbridge.co.uk'};

        // Attach the Salesforce Files
        if (!versionIds.isEmpty()) {
            mail.setEntityAttachments(versionIds);
        }
        // 5. Send it
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }//added for test 22:30
        policy.Documents_for_partners_sent__c = True;
        update policy;
    }
    
    public static void sendCancellationEmail(String policyNo){
        // 1. Fetch the Policy and its Related Files
        Policy__c policy = [SELECT Id, Name,Account_Partner_ID__c FROM Policy__c WHERE Name =: policyNo Limit 1];//'TST-KCI-1803BB' LIMIT 1];//'a1VAd00000615YT'
        
        if (!Test.isRunningTest()) {//added for test 22:30
        //1. Fetch the Partner Account related to policy
        Account partnerAccount =[SELECT Id, Name,RecordType.Name,Partner_ID__c From Account Where RecordType.Name='Partner Accounts' And Partner_ID__c=:policy.Account_Partner_ID__c];
        
        // 3. Fetch the Contact
        Contact targetContact = [SELECT Id,LastName, Email FROM Contact WHERE LastName='AutoDocsEmail' And Account.Name =: partnerAccount.Name LIMIT 1];//'lukasz.zawieja@gmail.com' LIMIT 1];
        
        // 4. Get the Email Template
        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Partner_Policy_Cancelation_VF' LIMIT 1];

        // 5. Construct the Email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        // Set the target: Who receives it and what record provides the merge data
        mail.setTargetObjectId(targetContact.Id);
        mail.setWhatId(policy.Id); // This allows the VF template to use the Policy fields
        mail.setTemplateId(template.Id);
        //mail.toAddresses = new String[]{'lukasz.zawieja@kingsbridge.co.uk'};
        
        // 6. Send it
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }//added for test 22:30
    }
    
}*/
public class SendAutoDocsEmail {

    @future   
    public static void sendPurchaseEmail(String policyNo){

        Policy__c policy = [
            SELECT Id, Name, Account_Partner_ID__c 
            FROM Policy__c 
            WHERE Name = :policyNo 
            LIMIT 1
        ];

        // Always run this logic (so it gets coverage)
        Account partnerAccount = [
            SELECT Id, Name, RecordType.Name, Partner_ID__c 
            FROM Account 
            WHERE RecordType.Name='Partner Accounts' 
            AND Partner_ID__c = :policy.Account_Partner_ID__c
            LIMIT 1
        ];
        
        Contact targetContact = [
            SELECT Id, LastName, Email 
            FROM Contact 
            WHERE LastName='AutoDocsEmail' 
            AND AccountId = :partnerAccount.Id 
            LIMIT 1
        ];
        
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :policy.Id
        ];

        List<Id> docIds = new List<Id>();
        for (ContentDocumentLink cdl : links) {
            docIds.add(cdl.ContentDocumentId);
        }

        List<ContentVersion> versions = [
            SELECT Id 
            FROM ContentVersion 
            WHERE ContentDocumentId IN :docIds 
            AND IsLatest = true
        ];

        List<Id> versionIds = new List<Id>();
        for (ContentVersion cv : versions) {
            versionIds.add(cv.Id);
        }

        EmailTemplate template = [
            SELECT Id 
            FROM EmailTemplate 
            WHERE DeveloperName = 'Partner_Policy_Purchase_VF' 
            LIMIT 1
        ];

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(targetContact.Id);
        mail.setWhatId(policy.Id);
        mail.setTemplateId(template.Id);

        if (!versionIds.isEmpty()) {
            mail.setEntityAttachments(versionIds);
        }

        // ONLY skip the actual send
        if (!Test.isRunningTest()) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }

        policy.Documents_for_partners_sent__c = true;
        update policy;
    }
    
    public static void sendCancellationEmail(String policyNo){
        // 1. Fetch the Policy and its Related Files
        Policy__c policy = [SELECT Id, Name,Account_Partner_ID__c FROM Policy__c WHERE Name =: policyNo Limit 1];//'TST-KCI-1803BB' LIMIT 1];//'a1VAd00000615YT'
        
        //if (!Test.isRunningTest()) {//added for test 22:30
        //1. Fetch the Partner Account related to policy
        Account partnerAccount =[SELECT Id, Name,RecordType.Name,Partner_ID__c From Account Where RecordType.Name='Partner Accounts' And Partner_ID__c=:policy.Account_Partner_ID__c];
        
        // 3. Fetch the Contact
        Contact targetContact = [SELECT Id,LastName, Email FROM Contact WHERE LastName='AutoDocsEmail' And Account.Name =: partnerAccount.Name LIMIT 1];//'lukasz.zawieja@gmail.com' LIMIT 1];
        
        // 4. Get the Email Template
        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Partner_Policy_Cancelation_VF' LIMIT 1];

        // 5. Construct the Email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        // Set the target: Who receives it and what record provides the merge data
        mail.setTargetObjectId(targetContact.Id);
        mail.setWhatId(policy.Id); // This allows the VF template to use the Policy fields
        mail.setTemplateId(template.Id);
        //mail.toAddresses = new String[]{'lukasz.zawieja@kingsbridge.co.uk'};
        
        // 6. Send it
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    //}
}