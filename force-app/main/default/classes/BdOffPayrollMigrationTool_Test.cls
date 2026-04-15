@IsTest
private class BdOffPayrollMigrationTool_Test {

    // ======================
    // Helpers / Test Factory
    // ======================

    // Retrieve the existing Partner_Opportunity RT from the org (fail fast if missing)
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
            'Expected Opportunity Record Type with DeveloperName "Partner_Opportunity" to exist.'
        );
        return rts[0].Id;
    }

    // Create an Opportunity WITHOUT AccountId and with StageName='Qualification'
    private static Opportunity makeOpp(String oldStage) {
        Opportunity o = new Opportunity(
            Name                   = 'OPP - ' + oldStage + ' - ' + System.currentTimeMillis(),
            RecordTypeId           = partnerRtId(),
            StageName              = 'Qualification',
            CloseDate              = Date.today().addDays(30),
            Product_Type__c        = 'Off Payroll Protect',
            Migration_Old_Stage__c = oldStage
        );
        insert o;
        return o;
    }

    // Attach a Task to the Opportunity
    private static Task makeTask(Id whatId, String subject, String status) {
        Task t = new Task(
            WhatId   = whatId,
            Subject  = subject,
            Status   = status,
            Priority = 'Normal'
        );
        insert t;
        return t;
    }

    // ================
    // Positive Scenarios
    // ================


    @IsTest
    static void testMeetingBooked_Completes_For_ImplementingOffPayroll() {
        Opportunity o = makeOpp('Implementing Off Payroll');
        Task t = makeTask(o.Id, 'Meeting Booked', 'Not Started');

        Test.startTest();
        BdOffPayrollMigrationTool.SetSpecifiedApTasks('Meeting Booked');
        Test.stopTest();

        t = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertEquals('Completed', t.Status,
            'Meeting Booked should complete when old stage is Implementing Off Payroll');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Negotiation', o.StageName,
            'Implementing Off Payroll should map to Negotiation');
    }

    @IsTest
    static void testMeetingAttended_Completes_For_ImplementingOffPayroll() {
        Opportunity o = makeOpp('Implementing Off Payroll');
        Task t = makeTask(o.Id, 'Meeting Attended', 'Not Started');

        Test.startTest();
        BdOffPayrollMigrationTool.SetSpecifiedApTasks('Meeting Attended');
        Test.stopTest();

        t = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertEquals('Completed', t.Status,
            'Meeting Attended should complete when old stage is Implementing Off Payroll');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Negotiation', o.StageName);
    }

    @IsTest
    static void testSupplyChainConfirmation_Completes_For_ImplementingOffPayroll() {
        Opportunity o = makeOpp('Implementing Off Payroll');
        Task t = makeTask(o.Id, 'Supply Chain Confirmation', 'Not Started');

        Test.startTest();
        BdOffPayrollMigrationTool.SetSpecifiedApTasks('Supply Chain Confirmation');
        Test.stopTest();

        t = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertEquals('Completed', t.Status,
            'Supply Chain Confirmation should complete when old stage is Implementing Off Payroll');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Negotiation', o.StageName);
    }


    // ================
    // Negative Scenarios
    // ================

    @IsTest
    static void testDiscoveryCall_DoesNotComplete_TooEarly() {
        Opportunity o = makeOpp('Booking Meeting'); // earlier than required for completion
        Task t = makeTask(o.Id, 'Discovery Call', 'Not Started');

        Test.startTest();
        BdOffPayrollMigrationTool.SetSpecifiedApTasks('Discovery Call');
        Test.stopTest();

        t = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertNotEquals('Completed', t.Status,
            'Discovery Call should NOT complete at Booking Meeting');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Qualification', o.StageName,
            'Booking Meeting should map to Qualification');
    }

    @IsTest
    static void testMeetingAttended_DoesNotComplete_UnlessImplementing() {
        Opportunity o = makeOpp('Completing Meeting'); // only Implementing Off Payroll should complete
        Task t = makeTask(o.Id, 'Meeting Attended', 'Not Started');

        Test.startTest();
        BdOffPayrollMigrationTool.SetSpecifiedApTasks('Meeting Attended');
        Test.stopTest();

        t = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertNotEquals('Completed', t.Status,
            'Meeting Attended should NOT complete at Completing Meeting');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Negotiation', o.StageName,
            'Completing Meeting should map to Negotiation');
    }

    @IsTest
    static void testProposalLinkSent_DoesNotComplete_UnlessSale() {
        Opportunity o = makeOpp('Implementing Off Payroll'); // only 'Off Payroll Protect Sale' should complete
        Task t = makeTask(o.Id, 'Proposal Link Sent', 'Not Started');

        Test.startTest();
        BdOffPayrollMigrationTool.SetSpecifiedApTasks('Proposal Link Sent');
        Test.stopTest();

        t = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertNotEquals('Completed', t.Status,
            'Proposal Link Sent should NOT complete unless at Off Payroll Protect Sale');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Negotiation', o.StageName);
    }

    @IsTest
    static void testProposalUWQuoteSent_CompletesOnly_For_Sale_Vs_NotTakenUp() {
        // Two opps processed in one call; ensure both have matching tasks
        Opportunity o1 = makeOpp('Off Payroll Protect Sale'); // completes + Closed
        Task t1 = makeTask(o1.Id, 'Proposal UW Quote Sent', 'Not Started');

        Opportunity o2 = makeOpp('Closed - Not Taken Up');    // should NOT complete + Closed
        Task t2 = makeTask(o2.Id, 'Proposal UW Quote Sent', 'Not Started');

        Test.startTest();
        BdOffPayrollMigrationTool.SetSpecifiedApTasks('Proposal UW Quote Sent');
        Test.stopTest();

        t1 = [SELECT Status FROM Task WHERE Id = :t1.Id];
        t2 = [SELECT Status FROM Task WHERE Id = :t2.Id];

        System.assertEquals('Completed', t1.Status, 'Should complete at Off Payroll Protect Sale');
        System.assertNotEquals('Completed', t2.Status, 'Should not complete at Closed - Not Taken Up');

        o1 = [SELECT StageName FROM Opportunity WHERE Id = :o1.Id];
        o2 = [SELECT StageName FROM Opportunity WHERE Id = :o2.Id];

        System.assertEquals('Closed', o1.StageName);
        System.assertEquals('Closed', o2.StageName);
    }

    // =================
    // Stage Mapping Only
    // =================


    // ==========================
    // Exclusion / No-Data Safety
    // ==========================

    @IsTest
    static void testIgnoresBlankOldStage_NoChange() {
        // Excluded by SOQL: Migration_Old_Stage__c != ''
        Opportunity o = new Opportunity(
            Name                   = 'OPP - Blank Old Stage - ' + System.currentTimeMillis(),
            RecordTypeId           = partnerRtId(),
            StageName              = 'Qualification',
            CloseDate              = Date.today().addDays(30),
            Product_Type__c        = 'Off Payroll Protect',
            Migration_Old_Stage__c = '' // excluded
        );
        insert o;

        Task t = makeTask(o.Id, 'Meeting Booked', 'Not Started');

        Test.startTest();
        BdOffPayrollMigrationTool.SetSpecifiedApTasks('Meeting Booked');
        Test.stopTest();

        // Should remain unchanged
        t = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertEquals('Not Started', t.Status, 'Task should remain unchanged for excluded Opportunity.');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Qualification', o.StageName, 'Stage should remain unchanged for excluded Opportunity.');
    }

    @IsTest
    static void testNoMatchingOpps_Safe() {
        // No matching Opps created -> method should not throw
        Test.startTest();
        BdOffPayrollMigrationTool.SetSpecifiedApTasks('Supply Chain Confirmation');
        Test.stopTest();

        System.assert(true, 'Method should be safe when no Opportunities match.');
    }
}