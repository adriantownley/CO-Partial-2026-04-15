@isTest
private class EmailToLeadProcessorTest {
    @isTest
    
    static void testHandleInboundEmailCreatesLead() {
        // Step 1: Get the RecordType for Lead
        Id rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Lead' and Name ='Customer Lead' Limit 1].Id;
        User u = [SELECT Id FROM User WHERE IsActive=true and Profile.Name = 'System Administrator' Limit 1];
        
        // Step 2: Create a mock inbound email
        System.runAs(u){
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = 'testuser@example.com';
        email.subject = 'Test Lead Creation';
        email.plainTextBody = 'This is a test email body.';

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        // Step 3: Call the handler
        EmailToLeadProcessor processor = new EmailToLeadProcessor();
        Messaging.InboundEmailResult result = processor.handleInboundEmail(email, env);

        // Step 4: Verify the result
        System.assertEquals(true, result.success, 'Email handler should return success');

        // Step 5: Verify the Lead was created
        Lead createdLead = [SELECT Id, LastName, Status, RecordTypeId, Source__c, Description, Referred_By_Email__c 
                            FROM Lead WHERE Referred_By_Email__c = :email.fromAddress LIMIT 1];

        System.assertEquals('Refer@kingsbridge lead', createdLead.LastName);
        System.assertEquals('New', createdLead.Status);
        System.assertEquals('Direct', createdLead.Source__c);
        System.assertEquals('Content of the email:\n' + email.plainTextBody, createdLead.Description);
        System.assertEquals(email.fromAddress, createdLead.Referred_By_Email__c);
    }
  }
}