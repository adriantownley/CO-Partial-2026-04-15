// In order for this test to pass "Account: Partner Account ID Auto Number" flow needs to get deactivated
// as it's autogenerates value for Partner_ID__c that cannot be overriten when creating a test data
@isTest
public class ContactForAutoDocsTest {

    @testSetup
    static void setupData() {

        // Get correct RecordType
        RecordType rt = [
            SELECT Id 
            FROM RecordType 
            WHERE Name = 'Partner Accounts' 
            AND SobjectType = 'Account' 
            LIMIT 1
        ];

        // Create Account WITHOUT setting Partner_ID__c
        Account acc = new Account(
            Name = 'Test Partner',
            Policy_Documents_Email__c = 'policy@test.com',
            Cancellation_Notification_Email__c = 'cancel@test.com',
            Partner_ID__c='P-99999',
            RecordTypeId = rt.Id
        );

        insert acc;

        // Re-query to get Flow-generated Partner_ID__c
        acc = [
            SELECT Id, Partner_ID__c 
            FROM Account 
            WHERE Id = :acc.Id
        ];

        // Safety check (important if Flow doesn't run in test)
        System.assertNotEquals(null, acc.Partner_ID__c, 'Partner_ID__c should be populated by Flow');
    }

    @isTest
    static void testCreateNewContacts() {

        Account acc = [
            SELECT Id, Partner_ID__c, Policy_Documents_Email__c, Cancellation_Notification_Email__c
            FROM Account 
            LIMIT 1
        ];

        Test.startTest();
        new ContactForAutoDocs().createOrFetchContact(acc.Partner_ID__c);
        Test.stopTest();

        List<Contact> contacts = [
            SELECT Id, Email 
            FROM Contact 
            WHERE AccountId = :acc.Id
        ];

        System.assertEquals(2, contacts.size(), 'Two contacts should be created');

        Set<String> emails = new Set<String>();
        for(Contact c : contacts){
            emails.add(c.Email);
        }

        System.assert(emails.contains(acc.Policy_Documents_Email__c));
        System.assert(emails.contains(acc.Cancellation_Notification_Email__c));
    }

    @isTest
    static void testUseExistingContacts() {

        Account acc = [
            SELECT Id, Partner_ID__c, Policy_Documents_Email__c, Cancellation_Notification_Email__c
            FROM Account 
            LIMIT 1
        ];

        // Insert existing contacts (to hit "if" branches)
        insert new List<Contact>{
            new Contact(
                LastName = 'AutoDocsEmail',
                Email = acc.Policy_Documents_Email__c,
                AccountId = acc.Id
            ),
            new Contact(
                LastName = 'AutoDocsEmailForCancellation',
                Email = acc.Cancellation_Notification_Email__c,
                AccountId = acc.Id
            )
        };

        Test.startTest();
        new ContactForAutoDocs().createOrFetchContact(acc.Partner_ID__c);
        Test.stopTest();

        // Ensure no duplicates created
        List<Contact> contacts = [
            SELECT Id FROM Contact WHERE AccountId = :acc.Id
        ];

        System.assertEquals(2, contacts.size(), 'No duplicate contacts should be created');
    }
}