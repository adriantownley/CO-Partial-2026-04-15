public class SendEmailFromSF { 
    @future
    public static void sendEmailAsync(String policyNo) {
        sendEmail(policyNo); // existing logic
    }

    public static void sendEmail(String policyNo) {
        // 0. Get Policy and email address to send the docs to
        Policy__c policy = [
            SELECT Id, Name,Partner_Owner_Email__c FROM Policy__c where Name =: policyNo //'TST-KCI-230725'
            LIMIT 1
        ];
        
        //XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
        // 0a. Email Address to send the docs to:
        Account account = [ select ID,Name,Type,Policy_Documents_Email__c,Cancellation_Notification_Email__c from Account Where Partner_ID__c =: policy.Account_Partner_ID__c Limit 1
        ];
        //XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
        
        // 1. Get the template
        EmailTemplate template = [
            SELECT Id 
            FROM EmailTemplate 
            WHERE DeveloperName = 'Partner_Policy_Purchase_VF' 
            LIMIT 1
        ];

        // 2. Get the sender User (ABC)
        User sender = [
            SELECT Id, Name, Email 
            FROM User 
            WHERE Name = 'Lukasz Zawieja' 
            LIMIT 1
        ];

        // 3. Create a dummy contact to use as recipient (since targetObjectId is required)
        Contact dummyRecipient = [SELECT Id from Contact where email='lukasz.zawieja@gmail.com' Limit 1];
        //XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
        //added bellow to use partner contact rather than my email:
        // 1. Fetch the Partner Account
        /*Account partner = [SELECT Id, Name, Partner_ID__c, Cancellation_Notification_Email__c, Policy_Documents_Email__c 
                   FROM Account 
                   WHERE Name = 'Test Partner 4000' 
                   LIMIT 1];

        String targetEmail = partner.Policy_Documents_Email__c;
        Contact autoDocContact;

        // 2. Check for an existing contact with the same Email and Account
        List<Contact> existingContacts = [SELECT Id FROM Contact 
                                  WHERE Email = :targetEmail 
                                  AND AccountId = :partner.Id 
                                  LIMIT 1];

        if (!existingContacts.isEmpty()) {
            // 3. Use the existing contact
            autoDocContact = existingContacts[0];
        } else {
            // 4. Create a new one if no duplicate exists
            autoDocContact = new Contact(
                LastName = 'AutoDocsEmail',
                AccountId = partner.Id, // Use AccountId field for assignment
                Email = targetEmail
            );
            insert autoDocContact;
        }*/
        
        //XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
        // Step 3: Collect all attachments (legacy Attachment + modern Files)
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();

        // Legacy Attachments
        List<Attachment> oldAttachments = [
            SELECT Name, Body 
            FROM Attachment 
            WHERE ParentId = :policy.Id
        ];
        for (Attachment att : oldAttachments) {
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(att.Name);
            efa.setBody(att.Body);
            attachments.add(efa);
        }

        // Files (ContentDocument)
        List<ContentDocumentLink> docLinks = [
            SELECT ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :policy.Id
        ];

        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink link : docLinks) {
            docIds.add(link.ContentDocumentId);
        }

        if (!docIds.isEmpty()) {
            List<ContentVersion> versions = [
                SELECT Title, VersionData 
                FROM ContentVersion 
                WHERE ContentDocumentId IN :docIds AND IsLatest = true
            ];

            for (ContentVersion version : versions) {
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(version.Title);
                efa.setBody(version.VersionData);
                attachments.add(efa);
            }
        }

        // 4. Create the email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        //mail.toAddresses = new String[]{'lukasz.zawieja@gmail.com','lukasz.zawieja@kingsbridge.co.uk'};
        mail.toAddresses = new String[]{policy.Partner_Owner_Email__c};
        mail.setTemplateId(template.Id);
        mail.setTargetObjectId(dummyRecipient.Id); // recipient
        //mail.setTargetObjectId(autoDocContact.Id); // recipient
        mail.setSenderDisplayName(sender.Name);
        mail.setSaveAsActivity(false);
        mail.setFileAttachments(attachments);//added 4 attachments
        mail.setWhatId(null); // if you want to link to a record, set WhatId

        // 5. Send it
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        
        //6. Update policy
        policy.Documents_for_partners_sent__c = true;
        update policy;
    }
}