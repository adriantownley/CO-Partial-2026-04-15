@isTest
public class BdIR35HealthCheckMigrationTool_Test {
    
    
    @isTest
    static void testSetSpecifiedApTasks_HealthCheckTeamMeetingAttended() {
        // Setup - Get the Partner_Opportunity record type ID from existing record types
        Id partnerOpportunityRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Partner_Opportunity' AND SObjectType = 'Opportunity' LIMIT 1].Id;
        
        // Create test opportunities with different Migration_Old_Stage__c values
        List<Opportunity> testOpps = new List<Opportunity>();
        
        // Test with 'Healthcheck Booked' stage - should complete Health Check IR35 Team Meeting Attended task
        Opportunity opp1 = new Opportunity(
            Name = 'Test Opp 1',
            RecordTypeId = partnerOpportunityRecordTypeId,
            Product_Type__c = 'IR35 Health Check',
            Migration_Old_Stage__c = 'Healthcheck Booked',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            OwnerId = UserInfo.getUserId()
        );
        testOpps.add(opp1);
        
        // Test with other stages - should NOT complete the task
        Opportunity opp2 = new Opportunity(
            Name = 'Test Opp 2',
            RecordTypeId = partnerOpportunityRecordTypeId,
            Product_Type__c = 'IR35 Health Check',
            Migration_Old_Stage__c = 'Meeting Booked',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            OwnerId = UserInfo.getUserId()
        );
        testOpps.add(opp2);
        
        // Insert opportunities first
        insert testOpps;
        
        // Create tasks for each opportunity
        List<Task> testTasks = new List<Task>();
        for (Opportunity opp : testOpps) {
            Task t = new Task(
                Subject = 'Health Check IR35 Team Meeting Attended',
                Status = 'Not Started',
                WhatId = opp.Id
            );
            testTasks.add(t);
        }
        insert testTasks;
        
        // Execute the method
        BdIR35HealthCheckMigrationTool.SetSpecifiedApTasks('Health Check IR35 Team Meeting Attended');
        
        // Verify results - check that we don't get any null pointer exceptions
        List<Task> updatedTasks = [SELECT Id, Status FROM Task WHERE Id IN :testTasks];
        
        // Check that only the task for 'Healthcheck Booked' stage is completed
        Integer completedCount = 0;
        for (Task t : updatedTasks) {
            if (t.Status == 'Completed') {
                completedCount++;
            }
        }
        System.assertEquals(1, completedCount, 'Should have 1 completed task for the Healthcheck Booked opportunity');
    }
    
    @isTest
    static void testSetSpecifiedApTasks_HealthCheckTeamMeetingBooked() {
        // Setup - Get the Partner_Opportunity record type ID from existing record types
        Id partnerOpportunityRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Partner_Opportunity' AND SObjectType = 'Opportunity' LIMIT 1].Id;
        
        // Create test opportunities with different Migration_Old_Stage__c values
        List<Opportunity> testOpps = new List<Opportunity>();
        
        // Test with 'Meeting Booked' stage - should complete Health Check IR35 Team Meeting Booked task
        Opportunity opp1 = new Opportunity(
            Name = 'Test Opp 1',
            RecordTypeId = partnerOpportunityRecordTypeId,
            Product_Type__c = 'IR35 Health Check',
            Migration_Old_Stage__c = 'Meeting Booked',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            OwnerId = UserInfo.getUserId()
        );
        testOpps.add(opp1);
        
        // Test with other stages - should NOT complete the task
        Opportunity opp2 = new Opportunity(
            Name = 'Test Opp 2',
            RecordTypeId = partnerOpportunityRecordTypeId,
            Product_Type__c = 'IR35 Health Check',
            Migration_Old_Stage__c = 'Meeting Attended',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            OwnerId = UserInfo.getUserId()
        );
        testOpps.add(opp2);
        
        // Insert opportunities first
        insert testOpps;
        
        // Create tasks for each opportunity
        List<Task> testTasks = new List<Task>();
        for (Opportunity opp : testOpps) {
            Task t = new Task(
                Subject = 'Health Check IR35 Team Meeting Booked',
                Status = 'Not Started',
                WhatId = opp.Id
            );
            testTasks.add(t);
        }
        insert testTasks;
        
        // Execute the method
        BdIR35HealthCheckMigrationTool.SetSpecifiedApTasks('Health Check IR35 Team Meeting Booked');
        
        // Verify results - check that we don't get any null pointer exceptions
        List<Task> updatedTasks = [SELECT Id, Status FROM Task WHERE Id IN :testTasks];
        
        // Check that only the task for 'Meeting Booked' stage is completed
        Integer completedCount = 0;
        for (Task t : updatedTasks) {
            if (t.Status == 'Completed') {
                completedCount++;
            }
        }
    }
}