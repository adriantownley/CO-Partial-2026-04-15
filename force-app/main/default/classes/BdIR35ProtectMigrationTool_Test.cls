@IsTest
private class BdIR35ProtectMigrationTool_Test {

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
            Name                   = 'IR35Protect Opp - ' + oldStage + ' - ' + System.currentTimeMillis(),
            RecordTypeId           = partnerRtId(),
            StageName              = 'Qualification', // per your requirement
            CloseDate              = Date.today().addDays(30),
            Product_Type__c        = 'IR35 Protect Insurance',     // matches the class filter
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
    static void testMeetingBooked_Completes_For_CompletingMeeting() {
        Opportunity o = makeOpp('Completing Meeting');
        Task t = makeTask(o.Id, 'Meeting Booked', 'Not Started');

        Test.startTest();
        BdIR35ProtectMigrationTool.SetSpecifiedApTasks('Meeting Booked');
        Test.stopTest();

        t = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertEquals('Completed', t.Status,
            'Meeting Booked should complete when old stage is Completing Meeting');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Negotiation', o.StageName);
    }

    @IsTest
    static void testMeetingBooked_Completes_For_InsertingParagraph() {
        Opportunity o = makeOpp('Inserting Paragraph/IR35 Secure Turned On');
        Task t = makeTask(o.Id, 'Meeting Booked', 'Not Started');

        Test.startTest();
        BdIR35ProtectMigrationTool.SetSpecifiedApTasks('Meeting Booked');
        Test.stopTest();

        t = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertEquals('Completed', t.Status,
            'Meeting Booked should complete when old stage is Inserting Paragraph/IR35 Secure Turned On');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Implementation', o.StageName);
    }

    @IsTest
    static void testMeetingAttended_Completes_For_InsertingParagraph() {
        Opportunity o = makeOpp('Inserting Paragraph/IR35 Secure Turned On');
        Task t = makeTask(o.Id, 'Meeting Attended', 'Not Started');

        Test.startTest();
        BdIR35ProtectMigrationTool.SetSpecifiedApTasks('Meeting Attended');
        Test.stopTest();

        t = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertEquals('Completed', t.Status,
            'Meeting Attended should complete when old stage is Inserting Paragraph/IR35 Secure Turned On');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Implementation', o.StageName);
    }

    // ================
    // Negative Scenarios
    // ================

    @IsTest
    static void testDiscoveryCall_DoesNotComplete_At_WorkingOutDM() {
        Opportunity o = makeOpp('Working out decision maker');
        Task t = makeTask(o.Id, 'Discovery Call', 'Not Started');

        Test.startTest();
        BdIR35ProtectMigrationTool.SetSpecifiedApTasks('Discovery Call');
        Test.stopTest();

        t = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertNotEquals('Completed', t.Status,
            'Discovery Call should NOT complete at Working out decision maker');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Qualification', o.StageName,
            'Working out decision maker should map to Qualification');
    }

    @IsTest
    static void testMeetingBooked_DoesNotComplete_At_BookingMeeting() {
        Opportunity o = makeOpp('Booking Meeting');
        Task t = makeTask(o.Id, 'Meeting Booked', 'Not Started');

        Test.startTest();
        BdIR35ProtectMigrationTool.SetSpecifiedApTasks('Meeting Booked');
        Test.stopTest();

        t = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertNotEquals('Completed', t.Status,
            'Meeting Booked should NOT complete at Booking Meeting');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Negotiation', o.StageName,
            'Booking Meeting should map to Negotiation');
    }

    @IsTest
    static void testMeetingAttended_DoesNotComplete_At_CompletingMeeting() {
        Opportunity o = makeOpp('Completing Meeting');
        Task t = makeTask(o.Id, 'Meeting Attended', 'Not Started');

        Test.startTest();
        BdIR35ProtectMigrationTool.SetSpecifiedApTasks('Meeting Attended');
        Test.stopTest();

        t = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertNotEquals('Completed', t.Status,
            'Meeting Attended should NOT complete at Completing Meeting');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Negotiation', o.StageName);
    }

    // =================
    // Stage Mapping Only
    // (Call once per opp to avoid static state pitfalls)
    // =================


    // ==========================
    // Exclusion / No-Data Safety
    // ==========================

    @IsTest
    static void testIgnoresBlankOldStage_NoChange() {
        // Excluded by SOQL: Migration_Old_Stage__c != ''
        Opportunity o = new Opportunity(
            Name                   = 'IR35Protect Opp - Blank Old Stage - ' + System.currentTimeMillis(),
            RecordTypeId           = partnerRtId(),
            StageName              = 'Qualification',
            CloseDate              = Date.today().addDays(30),
            Product_Type__c        = 'IR35 Protect Insurance',
            Migration_Old_Stage__c = '' // excluded
        );
        insert o;

        Task t = makeTask(o.Id, 'Meeting Booked', 'Not Started');

        Test.startTest();
        BdIR35ProtectMigrationTool.SetSpecifiedApTasks('Meeting Booked');
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
        BdIR35ProtectMigrationTool.SetSpecifiedApTasks('Discovery Call');
        Test.stopTest();

        System.assert(true, 'Method should be safe when no Opportunities match.');
    }

}