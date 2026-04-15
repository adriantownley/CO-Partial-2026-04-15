@isTest
public class PolicyEmailHandlerTest {

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
            Name = 'Test Policy 1',
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
    static void testQueueableJobEnqueue() {
        // Get a Policy name from setup
        Policy__c pol = [SELECT Name FROM Policy__c LIMIT 1];

        Test.startTest();

        // Enqueue the job
        System.enqueueJob(new PolicyEmailHandler(pol.Name));

        Test.stopTest();

        // Verify a queueable job was added
        List<AsyncApexJob> jobs = [SELECT Id, JobType, Status FROM AsyncApexJob WHERE JobType='Queueable'];

        System.assert(jobs.size() > 0, 'Expected a queueable job to be enqueued');
        System.assertEquals('Completed', jobs[0].Status, 'Job should have completed in test context');
    }

    @isTest
    static void testMultipleQueueables() {
        // Enqueue multiple jobs to ensure multiple instances work
        Policy__c pol = [SELECT Name FROM Policy__c LIMIT 1];

        Test.startTest();

        System.enqueueJob(new PolicyEmailHandler(pol.Name));
        System.enqueueJob(new PolicyEmailHandler(pol.Name));

        Test.stopTest();

        List<AsyncApexJob> jobs = [SELECT Id, JobType FROM AsyncApexJob WHERE JobType='Queueable'];
        System.assert(jobs.size() >= 2, 'Expected two queueable jobs to be enqueued');
    }
}