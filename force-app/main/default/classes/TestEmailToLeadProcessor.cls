@isTest
private class TestEmailToLeadProcessor {

    @isTest
    static void testHandleInboundEmail() {
        // Create a Partner Account with matching Email_Domain__c
        RecordType partnerRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Partner Accounts' LIMIT 1];

        Account partnerAccount = new Account(
            Name = 'Test Partner',
            RecordTypeId = partnerRt.Id,
            Email_Domain__c = 'gmail.com',
            Partner_ID__c = 'PARTNER123'
        );
        insert partnerAccount;

        // Create a test email
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.plainTextBody = 'This is a test inbound email';
        email.fromAddress = 'test17@gmail.com';

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        env.fromAddress = 'test17@gmail.com';

        // Call the class under test
        EmailToLeadProcessor processor = new EmailToLeadProcessor();
        Messaging.InboundEmailResult result = processor.handleInboundEmail(email, env);

        // Verify the result
        System.assertEquals(true, result.success, 'The result should be successful');

        // Verify the Lead was created
        Lead createdLead = [SELECT Email, FirstName, LastName, Company, Status, Description, Partner_ID__c 
                            FROM Lead WHERE Email = 'test17@gmail.com' LIMIT 1];

        System.assertEquals('Luke', createdLead.FirstName);
        System.assertEquals('Rosa 17', createdLead.LastName);
        System.assertEquals('JamnickBrix', createdLead.Company);
        System.assertEquals('Open - Not Contacted', createdLead.Status);
        System.assertEquals('This is a test inbound email', createdLead.Description);
        System.assertEquals('PARTNER123', createdLead.Partner_ID__c);
    }

    @isTest
    static void testHandleInboundEmailQueryException() {
        // Create a Partner Account so that at least the main flow passes
        RecordType partnerRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Partner Accounts' LIMIT 1];

        Account partnerAccount = new Account(
            Name = 'Test Partner',
            RecordTypeId = partnerRt.Id,
            Email_Domain__c = 'gmail.com',
            Partner_ID__c = 'PARTNER456'
        );
        insert partnerAccount;

        // Prepare an email with no matching lead to force QueryException in try-catch
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.plainTextBody = 'Another test email';
        email.fromAddress = 'notexisting@gmail.com';

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        env.fromAddress = 'notexisting@gmail.com';

        EmailToLeadProcessor processor = new EmailToLeadProcessor();
        Test.startTest();
        Messaging.InboundEmailResult result = processor.handleInboundEmail(email, env);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Handler should return success even with query exception');
    }
}