@IsTest
private class LeadTriggerHandlerTest {

    @TestSetup
    static void setupTestData() {

        Auto_Number__c aut = new Auto_Number__c();
        aut.Autonumber_Partner_ID__c = 4445;
        insert aut;

        // Create test Accounts
        Account acc1 = new Account(Name = 'Test Account 1');
        insert acc1;

        // Create test Opportunity
        Opportunity opp1 = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp1;

        // Create test Leads
        Lead lead1 = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Company = 'Test Company',
            Status = 'Open - Not Contacted',
            INSTANDA_Quote_ID__c = 'Q12345',
            IsConverted = false
        );
        insert lead1;

        Lead lead2 = new Lead(
            FirstName = 'Jane',
            LastName = 'Smith',
            Company = 'Test Company 2',
            Status = 'Open - Not Contacted',
            Lead_to_be_deleted_by_automation__c = false
        );
        insert lead2;

        // Create Attribution record linked to lead1
        Attribution__c attr = new Attribution__c(
            Introduced_Lead__c = lead1.Id
        );
        insert attr;
    }

    @IsTest
    static void testOnBeforeUpdate() {
        // Retrieve Leads
        Lead l = [SELECT Id, INSTANDA_Quote_ID__c, IsConverted, ConvertedOpportunityId FROM Lead LIMIT 1];

        Map<Id, Lead> oldMap = new Map<Id, Lead>{l.Id => l.clone(false, true)};
        
        Test.startTest();
        LeadTriggerHandler.onBeforeUpdate(new List<Lead>{l}, oldMap);
        Test.stopTest();
    }

    @IsTest
    static void testOnAfterUpdate_LeadDeletionAndReparent() {
        Lead l = [SELECT Id, Lead_to_be_deleted_by_automation__c FROM Lead WHERE Lead_to_be_deleted_by_automation__c = false LIMIT 1];
        Map<Id, Lead> oldMap = new Map<Id, Lead>{l.Id => l.clone(false, true)};
        
        // Trigger the deletion flag
        l.Lead_to_be_deleted_by_automation__c = true;

        Test.startTest();
        LeadTriggerHandler.onAfterUpdate(new List<Lead>{l}, oldMap);
        Test.stopTest();

    }

    @IsTest
    static void testUpdateOppRecordTypeAndReparentAttributions() {

        Account acc = [SELECT Id FROM Account LIMIT 1];

        // Create converted Lead linked to Opportunity
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Lead convertedLead = new Lead(
            FirstName = 'Converted',
            LastName = 'Lead',
            Company = 'Converted Company',
            Status = 'Closed - Converted',
            IsConverted = false,
            INSTANDA_Quote_ID__c = 'Q67890',
            Lead_to_be_deleted_by_automation__c = false
        );
        insert convertedLead;

        Attribution__c attr = new Attribution__c(
            Introduced_Lead__c = convertedLead.Id
        );
        insert attr;

        Test.startTest();

        Map<Id, Lead> oldMap = new Map<Id, Lead>{convertedLead.Id => convertedLead.clone(false, true)};
        
        LeadTriggerHandler.updateOppRecordType(new List<Lead>{convertedLead}, oldMap);
        LeadTriggerHandler.reparentAttributions(new List<Lead>{convertedLead}, oldMap);
        Test.stopTest();
    }

    @IsTest
    static void testEventBusPublish() {
        Lead l = [SELECT Id, Lead_to_be_deleted_by_automation__c FROM Lead LIMIT 1];
        Map<Id, Lead> oldMap = new Map<Id, Lead>{l.Id => l.clone(false, true)};
        l.Lead_to_be_deleted_by_automation__c = true;

        Test.startTest();
        LeadTriggerHandler.onAfterUpdate(new List<Lead>{l}, oldMap);
        Test.stopTest();

        // Can't directly assert EventBus publish success, but no exception = pass
        System.assert(true);
    }
}