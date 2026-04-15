@IsTest
private class BdIR35ToolMigrationTool_Test {

    // Helper to get the Partner_Opportunity record type id from the org.
    // Assumes it already exists; asserts if not found to fail fast.
    private static Id partnerRtId() {
        List<RecordType> rts = [
            SELECT Id
            FROM RecordType
            WHERE SobjectType = 'Opportunity'
              AND DeveloperName = 'Partner_Opportunity'
            LIMIT 1
        ];
        System.assertEquals(
            1, rts.size(),
            'Expected Record Type "Partner_Opportunity" to exist on Opportunity. ' +
            'Please create it or adjust the DeveloperName used by BdIR35ToolMigrationTool.'
        );
        return rts[0].Id;
    }

    // Helper to create an Opp with required fields + old stage.
    // Intentionally omits AccountId. Always seeds StageName = 'Qualification'.
    private static Opportunity makeOpp(String oldStage) {
        Opportunity o = new Opportunity(
            Name                   = 'IR35 Opp - ' + oldStage + ' - ' + System.currentTimeMillis(),
            RecordTypeId           = partnerRtId(),
            StageName              = 'Qualification', // per your requirement
            CloseDate              = Date.today().addDays(30),
            Product_Type__c        = 'IR35 Tool',
            Migration_Old_Stage__c = oldStage
        );
        insert o;
        return o;
    }

    // Helper to attach a Task with a given subject to the Opportunity
    private static Task makeTask(Id whatId, String subject, String status) {
        Task t = new Task(
            WhatId  = whatId,
            Subject = subject,
            Status  = status,
            Priority= 'Normal'
        );
        insert t;
        return t;
    }


    @IsTest
    static void testDemoBooked_Completes_For_SendingAgreement() {
        Opportunity o = makeOpp('Sending Agreement');             // starts at Qualification
        Task t = makeTask(o.Id, 'Demo Booked', 'Not Started');

        Test.startTest();
        BdIR35ToolMigrationTool.SetSpecifiedApTasks('Demo Booked');
        Test.stopTest();

        t = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertEquals('Completed', t.Status,
            'Demo Booked should be completed for old stage Sending Agreement');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Negotiation', o.StageName,
            'Old stage Sending Agreement should map to Negotiation');
    }

    @IsTest
    static void testDemoAttended_NotCompleted_WhenTooEarly() {
        Opportunity o = makeOpp('Booking Demo');                  // starts at Qualification
        Task t = makeTask(o.Id, 'Demo Attended', 'Not Started');

        Test.startTest();
        BdIR35ToolMigrationTool.SetSpecifiedApTasks('Demo Attended');
        Test.stopTest();

        t = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertNotEquals('Completed', t.Status,
            'Demo Attended should NOT complete for old stage Booking Demo');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Qualification', o.StageName,
            'Old stage Booking Demo should map to Qualification');
    }

    @IsTest
    static void testProposalSent_Completes_For_GettingAgreementSigned() {
        Opportunity o = makeOpp('Getting Agreement Signed');      // starts at Qualification
        Task t = makeTask(o.Id, 'Proposal Sent', 'Not Started');

        Test.startTest();
        BdIR35ToolMigrationTool.SetSpecifiedApTasks('Proposal Sent');
        Test.stopTest();

        t = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertEquals('Completed', t.Status,
            'Proposal Sent should complete at Getting Agreement Signed');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Negotiation', o.StageName,
            'Old stage Getting Agreement Signed should map to Negotiation');
    }

    @IsTest
    static void testAgreementSent_Completes_Only_For_GettingAgreementSigned() {
        Opportunity o1 = makeOpp('Getting Agreement Signed');     // starts at Qualification
        Task t1 = makeTask(o1.Id, 'Agreement Sent', 'Not Started');

        Opportunity o2 = makeOpp('Sending Agreement');            // starts at Qualification
        Task t2 = makeTask(o2.Id, 'Agreement Sent', 'Not Started');

        Test.startTest();
        BdIR35ToolMigrationTool.SetSpecifiedApTasks('Agreement Sent');
        Test.stopTest();

        t1 = [SELECT Status FROM Task WHERE Id = :t1.Id];
        t2 = [SELECT Status FROM Task WHERE Id = :t2.Id];

        System.assertEquals('Completed', t1.Status,
            'Agreement Sent should complete at Getting Agreement Signed');
        System.assertNotEquals('Completed', t2.Status,
            'Agreement Sent should not complete at Sending Agreement');

        o1 = [SELECT StageName FROM Opportunity WHERE Id = :o1.Id];
        o2 = [SELECT StageName FROM Opportunity WHERE Id = :o2.Id];

        System.assertEquals('Negotiation', o1.StageName);
        System.assertEquals('Negotiation', o2.StageName);
    }

    @IsTest
    static void testStageNegotiation_MappingOnly() {
        // StageName initially 'Qualification' by design
        Opportunity o = makeOpp('Completing Demo');
        Task t = makeTask(o.Id, 'Discovery Fact Find Complete', 'Not Started');

        Test.startTest();
        BdIR35ToolMigrationTool.SetSpecifiedApTasks('Discovery Fact Find Complete');
        Test.stopTest();

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Negotiation', o.StageName,
            'Old stage Completing Demo should map to Negotiation');
    }

    @IsTest
    static void testStageClosed_MappingOnly() {
        // StageName initially 'Qualification' by design
        Opportunity o = makeOpp('Tool Sold');
        Task t = makeTask(o.Id, 'Agreement Sent', 'Not Started');

        Test.startTest();
        BdIR35ToolMigrationTool.SetSpecifiedApTasks('Agreement Sent');
        Test.stopTest();

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Closed', o.StageName,
            'Old stage Tool Sold should map to Closed');
    }

    @IsTest
    static void testIgnoresBlankOldStage_NoCrash_NoChange() {
        // This Opp should NOT be picked up by the SOQL (Migration_Old_Stage__c != '')
        Opportunity o = new Opportunity(
            Name                   = 'IR35 Opp - Blank Old Stage - ' + System.currentTimeMillis(),
            RecordTypeId           = partnerRtId(),
            StageName              = 'Qualification',  // explicitly Qualification at creation
            CloseDate              = Date.today().addDays(30),
            Product_Type__c        = 'IR35 Tool',
            Migration_Old_Stage__c = ''                // excluded by the queried method
        );
        insert o;

        Task t = makeTask(o.Id, 'Demo Booked', 'Not Started');

        Test.startTest();
        BdIR35ToolMigrationTool.SetSpecifiedApTasks('Demo Booked');
        Test.stopTest();

        // Should be unchanged
        t = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertEquals('Not Started', t.Status,
            'Task should remain unchanged for opp excluded from query');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Qualification', o.StageName,
            'Stage should be unchanged for excluded opp');
    }

    @IsTest
    static void testNoMatchingOpps_Safe() {
        // No opportunities created matching the filter; method should not error
        Test.startTest();
        BdIR35ToolMigrationTool.SetSpecifiedApTasks('Demo Attended');
        Test.stopTest();

        System.assert(true, 'Method should be safe when no opportunities match.');
    }
}