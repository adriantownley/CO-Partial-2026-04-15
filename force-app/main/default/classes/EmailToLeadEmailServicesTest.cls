@IsTest
public class EmailToLeadEmailServicesTest {

    @IsTest
    static void testHandleInboundEmail() {

        Auto_Number__c aut = new Auto_Number__c();
        aut.Autonumber_Partner_ID__c = 4445;
        insert aut;
        
        RecordType partnerRT = [SELECT Id FROM RecordType WHERE Name = 'Partner Accounts' AND SObjectType = 'Account' LIMIT 1];
        Account partnerAcc = new Account(
            Name = 'Test Partner',
            RecordTypeId = partnerRT.Id,
            Email_Domain__c = 'kingsbridge.co.uk',
            Partner_ID__c = 'TEST123'
        );
        insert partnerAcc;

        Messaging.InboundEmail testEmail = new Messaging.InboundEmail();
        testEmail.subject = 'Test Lead Email';
        testEmail.fromAddress = 'referrer@kingsbridge.co.uk';
        testEmail.fromName = 'John Referrer';
        testEmail.plainTextBody = 
            'First Name: Jane ' +
            'Last Name: Doe ' +
            'Email Address: jane.doe@example.com ' +
            'Phone Number: 1234567890 ' +
            'Kind regards';

        Messaging.InboundEnvelope testEnv = new Messaging.InboundEnvelope();
        testEnv.fromAddress = 'referrer@kingsbridge.co.uk';

        Test.startTest();
        EmailToLeadEmailServices handler = new EmailToLeadEmailServices();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(testEmail, testEnv);
        Test.stopTest();
    }

    @IsTest
    static void testHandleInboundEmail_NoAccountOrContact() {

        Auto_Number__c aut = new Auto_Number__c();
        aut.Autonumber_Partner_ID__c = 4445;
        insert aut;
        
        Messaging.InboundEmail testEmail = new Messaging.InboundEmail();
        testEmail.subject = 'Test Lead Email';
        testEmail.fromAddress = 'unknown@domain.com';
        testEmail.fromName = 'Alice Referrer';
        testEmail.plainTextBody = 
            'First Name: Alice ' +
            'Last Name: Smith ' +
            'Email Address: alice.smith@example.com ' +
            'Phone Number: 9876543210 ' +
            'Kind regards';

        Messaging.InboundEnvelope testEnv = new Messaging.InboundEnvelope();
        testEnv.fromAddress = 'unknown@domain.com';

        RecordType partnerRT = [SELECT Id FROM RecordType WHERE Name = 'Partner Accounts' AND SObjectType = 'Account' LIMIT 1];
        Account defaultAcc = new Account(
            Name = 'Default Partner',
            RecordTypeId = partnerRT.Id,
            Partner_ID__c = 'KPS'
        );
        insert defaultAcc;

        Test.startTest();
        EmailToLeadEmailServices handler = new EmailToLeadEmailServices();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(testEmail, testEnv);
        Test.stopTest();
    }
}