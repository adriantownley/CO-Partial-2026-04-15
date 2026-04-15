@isTest
public class EmailDocumentsProcessorTest {

    @testSetup
    static void setupData() {

        // Get Record Types
        RecordType rt = [
            SELECT Id 
            FROM RecordType 
            WHERE Name = 'Partner Accounts' 
            AND SobjectType = 'Account' 
            LIMIT 1
        ];
        
        RecordType rt2 = [
            SELECT Id 
            FROM RecordType 
            WHERE Name = 'Customer Accounts' 
            AND SobjectType = 'Account' 
            LIMIT 1
        ];

        // Create Partner Account
        Account partnerAccount = new Account(
            Name = 'Test Partner',
            Policy_Documents_Email__c = 'policy@test.com',
            Cancellation_Notification_Email__c = 'cancel@test.com',
            Partner_ID__c = 'P-99999',
            RecordTypeId = rt.Id
        );
        insert partnerAccount;
        
        // Create Customer/Person Account
        Account personalAccount = new Account(
            LastName = 'TestPerson',
            Partner_ID__c = partnerAccount.Id,
            RecordTypeId = rt2.Id
        );
        insert personalAccount;
        
        // Create Policy record (Documents not received)
        Policy__c pol = new Policy__c(
            Customer__c = personalAccount.Id,
            Name = 'TST-KCI-100517',
            Cancellation_Reason__c = 'none',
            Status__c = 'Live',
            Value__c = 1,
            Term__c = 12,
            Partner_OLD__c = partnerAccount.Id, // drives formula Account_Partner_ID__c
            Number_of_Instalments__c = 10,
            Instalment_Amount__c = 100,
            Inception_Date_Time__c = System.today(),
            Expiry_Date_time__c = System.today(),
            Issue_Date_Time__c = System.today(),
            Documents_for_partners_received__c = false
        );
        insert pol;
    }

    @isTest
    static void testHandleInboundEmailWithPDF() {
        Policy__c pol = [SELECT Id, Name, Documents_for_partners_received__c, Account_Partner_ID__c FROM Policy__c LIMIT 1];

        // Create a fake PDF attachment
        Messaging.InboundEmail.BinaryAttachment pdfAttachment = new Messaging.InboundEmail.BinaryAttachment();
        pdfAttachment.body = Blob.valueOf('PDF CONTENT');
        pdfAttachment.filename = 'TestDoc.pdf';

        // Fake inbound email
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Policy ' + pol.Name + ' documents';
        email.binaryAttachments = new Messaging.InboundEmail.BinaryAttachment[] { pdfAttachment };

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        env.fromAddress = 'sender@test.com';

        Test.startTest();

        EmailDocumentsProcessor processor = new EmailDocumentsProcessor();
        Messaging.InboundEmailResult result = processor.handleInboundEmail(email, env);

        Test.stopTest();

        // Assertions
        System.assert(result.success, 'Email should be processed successfully');

        // Check that the Policy was updated
        pol = [SELECT Documents_for_partners_received__c FROM Policy__c WHERE Id = :pol.Id];
        System.assert(pol.Documents_for_partners_received__c, 'Policy flag should be updated to true');

        // Check that ContentDocumentLink exists
        List<ContentDocumentLink> cdlList = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :pol.Id];
        System.assert(cdlList.size() == 1, 'One PDF attachment should be linked to the Policy');
    }

    @isTest
    static void testHandleInboundEmailWithReceiptPDFIgnored() {
        Policy__c pol = [SELECT Id, Name FROM Policy__c LIMIT 1];

        // Attachment with filename 'Receipt.pdf' should be ignored
        Messaging.InboundEmail.BinaryAttachment receiptAttachment = new Messaging.InboundEmail.BinaryAttachment();
        receiptAttachment.body = Blob.valueOf('Receipt PDF CONTENT');
        receiptAttachment.filename = 'Receipt.pdf';

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Policy ' + pol.Name;
        email.binaryAttachments = new Messaging.InboundEmail.BinaryAttachment[] { receiptAttachment };

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        env.fromAddress = 'sender@test.com';

        Test.startTest();
        EmailDocumentsProcessor processor = new EmailDocumentsProcessor();
        Messaging.InboundEmailResult result = processor.handleInboundEmail(email, env);
        Test.stopTest();

        System.assert(result.success, 'Email should still be processed successfully');

        // Verify that no ContentDocumentLink was created for Receipt.pdf
        List<ContentDocumentLink> cdlList = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :pol.Id];
        System.assertEquals(0, cdlList.size(), 'Receipt.pdf attachment should be ignored');
    }

    @isTest
    static void testHandleInboundEmailWithInvalidSubject() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'NoPolicyHere';

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        env.fromAddress = 'sender@test.com';

        Test.startTest();
        EmailDocumentsProcessor processor = new EmailDocumentsProcessor();
        Messaging.InboundEmailResult result = processor.handleInboundEmail(email, env);
        Test.stopTest();

        System.assert(!result.success, 'Email with invalid subject should return success=false');
    }

    @isTest
    static void testHandleInboundEmailWithBlankPolicyNumber() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Policy    '; // spaces only after 'Policy'

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        env.fromAddress = 'sender@test.com';

        Test.startTest();
        EmailDocumentsProcessor processor = new EmailDocumentsProcessor();
        Messaging.InboundEmailResult result = processor.handleInboundEmail(email, env);
        Test.stopTest();

        System.assert(!result.success, 'Blank policy number should return success=false');
    }
}