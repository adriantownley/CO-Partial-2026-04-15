global class EmailDocumentsProcessor implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        try {
            // Look for Policy Number in Subject or Body
            String policyNumber;
            /*Policy__c policyX = [SELECT Id,TempField4Testing__c FROM Policy__c WHERE Name = 'TST-KCI-100517' Limit 1];
            policyX.TempField4Testing__c = 'Works 2';
            update policyX;*/
            if (email.subject != null && email.subject.contains('Policy')) {
                Integer startIndex = email.subject.indexOf('Policy') + 7;
                policyNumber = email.subject.substring(startIndex).trim().split(' ')[0];
                
                /*Policy__c policyX = [SELECT Id,TempField4Testing__c FROM Policy__c WHERE Name = 'TST-KCI-100517' Limit 1];
                policyX.TempField4Testing__c = policyNumber;
                update policyX;*/
            }

            if (String.isBlank(policyNumber)) {
                result.success = false;
                return result;
            }

            // Query for the Policy record
            List<Policy__c> policies = [SELECT Id,Name,Account_Partner_ID__c FROM Policy__c WHERE Name = :policyNumber LIMIT 1];
            if (policies.isEmpty()) {
                result.success = false;
                return result;
            }

            Policy__c policy = policies[0];
            //policy.Partner_Owner_Email__c='lukasz.zawieja@kingsbridge.co.uk';
            policy.Documents_for_partners_received__c = true;
            update policy;

            // Process attachments
            for (Messaging.InboundEmail.BinaryAttachment attachment : email.binaryAttachments) {
                if (attachment.filename.endsWithIgnoreCase('.pdf') && !attachment.filename.equalsIgnoreCase('Receipt.pdf')) { //added 2nd condition
                    // Use ContentVersion for modern file handling
                    ContentVersion cv = new ContentVersion();
                    cv.Title = attachment.filename;
                    cv.PathOnClient = attachment.filename;
                    cv.VersionData = attachment.body;
                    cv.Origin = 'H'; // 'H' stands for "Uploaded via Chatter"
                    insert cv;

                    // Associate ContentDocument with Policy__c using ContentDocumentLink
                    ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id LIMIT 1];
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = cd.Id;
                    cdl.LinkedEntityId = policy.Id;
                    cdl.ShareType = 'V'; // Viewer access
                    cdl.Visibility = 'AllUsers';
                    insert cdl;
                }
            }
            if (!Test.isRunningTest()) {
            //Create a contact for sending the docs
            ContactForAutoDocs ad = new ContactForAutoDocs();
            ad.createOrFetchContact(policy.Account_Partner_ID__c);
            }

            result.success = true;
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            result.success = false;
        }

        return result;
    }
}