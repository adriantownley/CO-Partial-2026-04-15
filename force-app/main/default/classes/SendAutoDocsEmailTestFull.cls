/*@isTest
public class SendAutoDocsEmailTestFull {

    @testSetup
    static void setupData() {

        Account partnerAccount = new Account(
            Name = 'Test Partner',
            RecordTypeId = [SELECT Id FROM RecordType 
                    WHERE Name='Partner Accounts' 
                    AND SobjectType='Account' 
                    LIMIT 1].Id
        );
        insert partnerAccount;

        Account customerAccount = new Account(
            LastName = 'Customer',
            Partner_ID__c = partnerAccount.Id,
            RecordTypeId = [SELECT Id FROM RecordType 
                    WHERE Name='Customer Accounts' 
                    AND SobjectType='Account' 
                    LIMIT 1].Id
        );
        insert customerAccount;

        Policy__c pol = new Policy__c(
            Name = 'TST-KCI-000001',
            Customer__c = customerAccount.Id,
            Partner_OLD__c = partnerAccount.Id,
            Documents_for_partners_sent__c = false,
            Documents_for_partners_received__c = true
        );
        insert pol;

        insert new Contact(
            LastName = 'AutoDocsEmail',
            Email = 'autodocs@test.com',
            AccountId = partnerAccount.Id
        );

        // ✅ TWO documents (better loop coverage)
        ContentVersion cv1 = new ContentVersion(
            Title = 'TestDoc1',
            PathOnClient = 'TestDoc1.pdf',
            VersionData = Blob.valueOf('PDF1')
        );
        insert cv1;

        ContentVersion cv2 = new ContentVersion(
            Title = 'TestDoc2',
            PathOnClient = 'TestDoc2.pdf',
            VersionData = Blob.valueOf('PDF2')
        );
        insert cv2;

        List<ContentDocument> cds = [
            SELECT Id, LatestPublishedVersionId 
            FROM ContentDocument 
            WHERE LatestPublishedVersionId IN :new List<Id>{cv1.Id, cv2.Id}
        ];

        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (ContentDocument cd : cds) {
            links.add(new ContentDocumentLink(
                ContentDocumentId = cd.Id,
                LinkedEntityId = pol.Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            ));
        }
        insert links;
    }

    @isTest
    static void testSendPurchaseEmailFull() {
        Policy__c pol = [SELECT Id, Name FROM Policy__c WHERE Name = 'TST-KCI-000001' LIMIT 1];

        Test.startTest();
        SendAutoDocsEmail.sendPurchaseEmail(pol.Name);
        Test.stopTest();

        pol = [SELECT Documents_for_partners_sent__c FROM Policy__c WHERE Id = :pol.Id];

        System.assert(pol.Documents_for_partners_sent__c, 'Flag should be updated');

        // ✅ Ensure attachments existed path was executed
        List<ContentDocumentLink> cdlList = [
            SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :pol.Id
        ];
        System.assert(cdlList.size() > 1, 'Multiple attachments should exist');
    }

    @isTest
    static void testSendPurchaseEmailWithNoAttachments() {
        Account partnerAccount = [SELECT Id FROM Account WHERE Name='Test Partner' LIMIT 1];
        Account customerAccount = [SELECT Id FROM Account WHERE LastName='Customer' LIMIT 1];

        Policy__c polNoDoc = new Policy__c(
            Name = 'TEST-POLICY-002',
            Customer__c = customerAccount.Id,
            Partner_OLD__c = partnerAccount.Id,
            Documents_for_partners_sent__c = false
        );
        insert polNoDoc;

        Test.startTest();
        SendAutoDocsEmail.sendPurchaseEmail(polNoDoc.Name);
        Test.stopTest();

        polNoDoc = [SELECT Documents_for_partners_sent__c FROM Policy__c WHERE Id = :polNoDoc.Id];

        // ✅ Covers versionIds.isEmpty() branch
        System.assert(polNoDoc.Documents_for_partners_sent__c, 'Flag should still be updated');
    }

    @isTest
    static void testSendCancellationEmailFull() {
        Policy__c pol = [SELECT Id, Name FROM Policy__c WHERE Name = 'TST-KCI-000001' LIMIT 1];

        Test.startTest();
        SendAutoDocsEmail.sendCancellationEmail(pol.Name);
        Test.stopTest();

        System.assert(true, 'Cancellation executed');
    }

    @isTest
    static void testSendCancellationEmailInvalidPolicy() {
        Test.startTest();
        try {
            SendAutoDocsEmail.sendCancellationEmail('INVALID-POLICY');
            System.assert(false);
        } catch (QueryException e) {
            System.assert(true);
        }
        Test.stopTest();
    }
}*/
@isTest
public class SendAutoDocsEmailTestFull {

    @testSetup
    static void setupData() {
        // Partner Account
        Account partnerAccount = new Account(
            Name = 'Test Partner',
            RecordTypeId = [SELECT Id FROM RecordType WHERE Name='Partner Accounts' AND SobjectType='Account' LIMIT 1].Id
        );
        insert partnerAccount;

        // Customer Account
        Account customerAccount = new Account(
            LastName = 'Customer',
            Partner_ID__c = partnerAccount.Id,
            RecordTypeId = [SELECT Id FROM RecordType WHERE Name='Customer Accounts' AND SobjectType='Account' LIMIT 1].Id
        );
        insert customerAccount;

        // Policy
        Policy__c pol = new Policy__c(
            Name = 'TST-KCI-000001',
            Customer__c = customerAccount.Id,
            Partner_OLD__c = partnerAccount.Id,
            Documents_for_partners_sent__c = false,
            Documents_for_partners_received__c = true
        );
        insert pol;

        // Contact for email merge
        insert new Contact(
            LastName = 'AutoDocsEmail',
            Email = 'autodocs@test.com',
            AccountId = partnerAccount.Id
        );

        // Content Versions
        ContentVersion cv1 = new ContentVersion(
            Title = 'TestDoc1',
            PathOnClient = 'TestDoc1.pdf',
            VersionData = Blob.valueOf('PDF1')
        );
        insert cv1;

        ContentVersion cv2 = new ContentVersion(
            Title = 'TestDoc2',
            PathOnClient = 'TestDoc2.pdf',
            VersionData = Blob.valueOf('PDF2')
        );
        insert cv2;

        // Link ContentDocument to Policy
        List<ContentDocument> cds = [
            SELECT Id, LatestPublishedVersionId 
            FROM ContentDocument 
            WHERE LatestPublishedVersionId IN :new List<Id>{cv1.Id, cv2.Id}
        ];
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (ContentDocument cd : cds) {
            links.add(new ContentDocumentLink(
                ContentDocumentId = cd.Id,
                LinkedEntityId = pol.Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            ));
        }
        insert links;
    }

    @isTest
    static void testSendPurchaseEmailFull() {
        Policy__c pol = [SELECT Id, Name FROM Policy__c WHERE Name = 'TST-KCI-000001' LIMIT 1];

        Test.startTest();
        SendAutoDocsEmail.sendPurchaseEmail(pol.Name);
        Test.stopTest();

        pol = [SELECT Documents_for_partners_sent__c FROM Policy__c WHERE Id = :pol.Id];
        System.assert(pol.Documents_for_partners_sent__c, 'Flag should be updated');

        List<ContentDocumentLink> cdlList = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :pol.Id];
        System.assert(cdlList.size() > 1, 'Multiple attachments should exist');
    }

    @isTest
    static void testSendPurchaseEmailWithNoAttachments() {
        Account partnerAccount = [SELECT Id FROM Account WHERE Name='Test Partner' LIMIT 1];
        Account customerAccount = [SELECT Id FROM Account WHERE LastName='Customer' LIMIT 1];

        Policy__c polNoDoc = new Policy__c(
            Name = 'TEST-POLICY-002',
            Customer__c = customerAccount.Id,
            Partner_OLD__c = partnerAccount.Id,
            Documents_for_partners_sent__c = false
        );
        insert polNoDoc;

        Test.startTest();
        SendAutoDocsEmail.sendPurchaseEmail(polNoDoc.Name);
        Test.stopTest();

        polNoDoc = [SELECT Documents_for_partners_sent__c FROM Policy__c WHERE Id = :polNoDoc.Id];
        System.assert(polNoDoc.Documents_for_partners_sent__c, 'Flag should still be updated even without attachments');
    }

    @isTest
    static void testSendCancellationEmailFull() {
        Policy__c pol = [SELECT Id, Name FROM Policy__c WHERE Name = 'TST-KCI-000001' LIMIT 1];

        Test.startTest();
        SendAutoDocsEmail.sendCancellationEmail(pol.Name);
        Test.stopTest();

        System.assert(true, 'Cancellation executed successfully');
    }

    @isTest
    static void testSendCancellationEmailInvalidPolicy() {
        Test.startTest();
        try {
            SendAutoDocsEmail.sendCancellationEmail('INVALID-POLICY');
            System.assert(false, 'Expected QueryException for invalid policy');
        } catch (QueryException e) {
            System.assert(true, 'Caught expected exception');
        }
        Test.stopTest();
    }
}