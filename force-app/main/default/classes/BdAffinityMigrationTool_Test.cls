@IsTest
private class BdAffinityMigrationTool_Test {

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
            Name                   = 'Affinity Opp - ' + oldStage + ' - ' + System.currentTimeMillis(),
            RecordTypeId           = partnerRtId(),
            StageName              = 'Qualification',              // per requirement
            CloseDate              = Date.today().addDays(30),
            Product_Type__c        = 'Public Liability Affinity',  // matches filter in class
            Migration_Old_Stage__c = oldStage
        );
        insert o;
        return o;
    }

    // Attach a Task to the Opportunity that matches the subject we will pass to the method
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
    static void test_MeetingBooked_Completes_CompletingMeeting() {
        Opportunity o = makeOpp('Completing Meeting');
        Task t = makeTask(o.Id, 'Meeting Booked', 'Not Started');

        Test.startTest();
        BdAffinityMigrationTool.SetSpecifiedApTasks('Meeting Booked');
        Test.stopTest();

        t = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertEquals('Completed', t.Status, 'Meeting Booked should complete at Completing Meeting');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Negotiation', o.StageName);
    }

    @IsTest
    static void test_MeetingBooked_Completes_ImplementingPartnership() {
        Opportunity o = makeOpp('Implementing Partnership');
        Task t = makeTask(o.Id, 'Meeting Booked', 'Not Started');

        Test.startTest();
        BdAffinityMigrationTool.SetSpecifiedApTasks('Meeting Booked');
        Test.stopTest();

        t = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertEquals('Completed', t.Status, 'Meeting Booked should complete at Implementing Partnership');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Implementation', o.StageName);
    }

    @IsTest
    static void test_MeetingAttended_Completes_ImplementingPartnership() {
        Opportunity o = makeOpp('Implementing Partnership');
        Task t = makeTask(o.Id, 'Meeting Attended', 'Not Started');

        Test.startTest();
        BdAffinityMigrationTool.SetSpecifiedApTasks('Meeting Attended');
        Test.stopTest();

        t = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertEquals('Completed', t.Status, 'Meeting Attended should complete at Implementing Partnership');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Implementation', o.StageName);
    }

    @IsTest
    static void test_AgreementSent_Completes_ImplementingPartnership() {
        Opportunity o = makeOpp('Implementing Partnership');
        Task t = makeTask(o.Id, 'Agreement Sent', 'Not Started');

        Test.startTest();
        BdAffinityMigrationTool.SetSpecifiedApTasks('Agreement Sent');
        Test.stopTest();

        t = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertEquals('Completed', t.Status, 'Agreement Sent should complete at Implementing Partnership');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Implementation', o.StageName);
    }

    @IsTest
    static void test_AgreementSigned_Completes_ImplementingPartnership() {
        Opportunity o = makeOpp('Implementing Partnership');
        Task t = makeTask(o.Id, 'Agreement Signed', 'Not Started');

        Test.startTest();
        BdAffinityMigrationTool.SetSpecifiedApTasks('Agreement Signed');
        Test.stopTest();

        t = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertEquals('Completed', t.Status, 'Agreement Signed should complete at Implementing Partnership');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Implementation', o.StageName);
    }

    // ================
    // Negative Scenarios (still return an opp + matching task)
    // ================

    @IsTest
    static void test_MeetingBooked_NotComplete_BookingMeeting() {
        Opportunity o = makeOpp('Booking Meeting');
        Task t = makeTask(o.Id, 'Meeting Booked', 'Not Started');

        Test.startTest();
        BdAffinityMigrationTool.SetSpecifiedApTasks('Meeting Booked');
        Test.stopTest();

        t = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertNotEquals('Completed', t.Status, 'Meeting Booked should NOT complete at Booking Meeting');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Qualification', o.StageName);
    }

    @IsTest
    static void test_MeetingAttended_NotComplete_CompletingMeeting() {
        Opportunity o = makeOpp('Completing Meeting');
        Task t = makeTask(o.Id, 'Meeting Attended', 'Not Started');

        Test.startTest();
        BdAffinityMigrationTool.SetSpecifiedApTasks('Meeting Attended');
        Test.stopTest();

        t = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertNotEquals('Completed', t.Status, 'Meeting Attended should NOT complete at Completing Meeting');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Negotiation', o.StageName);
    }

    @IsTest
    static void test_AgreementSent_NotComplete_BookingMeeting() {
        Opportunity o = makeOpp('Booking Meeting');
        Task t = makeTask(o.Id, 'Agreement Sent', 'Not Started');

        Test.startTest();
        BdAffinityMigrationTool.SetSpecifiedApTasks('Agreement Sent');
        Test.stopTest();

        t = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertNotEquals('Completed', t.Status, 'Agreement Sent should NOT complete at Booking Meeting');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Qualification', o.StageName);
    }

    @IsTest
    static void test_DiscoveryCall_NotComplete_WorkingOutDM() {
        Opportunity o = makeOpp('Working out decision maker');
        Task t = makeTask(o.Id, 'Discovery Call', 'Not Started');

        Test.startTest();
        BdAffinityMigrationTool.SetSpecifiedApTasks('Discovery Call');
        Test.stopTest();

        t = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertNotEquals('Completed', t.Status, 'Discovery Call should NOT complete at Working out decision maker');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Qualification', o.StageName);
    }

    // =================
    // Stage Mapping Only (1 opp per test; each has a matching task)
    // =================

    @IsTest
    static void test_StageMapping_WorkingOutDM_to_Qualification() {
        Opportunity o = makeOpp('Working out decision maker');
        makeTask(o.Id, 'Discovery Call', 'Not Started');

        Test.startTest();
        BdAffinityMigrationTool.SetSpecifiedApTasks('Discovery Call');
        Test.stopTest();

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Qualification', o.StageName);
    }

    @IsTest
    static void test_StageMapping_CompletingMeeting_to_Negotiation() {
        Opportunity o = makeOpp('Completing Meeting');
        makeTask(o.Id, 'Meeting Booked', 'Not Started');

        Test.startTest();
        BdAffinityMigrationTool.SetSpecifiedApTasks('Meeting Booked');
        Test.stopTest();

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Negotiation', o.StageName);
    }

    @IsTest
    static void test_StageMapping_ImplementingPartnership_to_Implementation() {
        Opportunity o = makeOpp('Implementing Partnership');
        makeTask(o.Id, 'Agreement Signed', 'Not Started');

        Test.startTest();
        BdAffinityMigrationTool.SetSpecifiedApTasks('Agreement Signed');
        Test.stopTest();

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Implementation', o.StageName);
    }

    @IsTest
    static void test_StageMapping_PartnerWon_to_Closed() {
        Opportunity o = makeOpp('Partner Won');
        makeTask(o.Id, 'Agreement Sent', 'Not Started');

        Test.startTest();
        BdAffinityMigrationTool.SetSpecifiedApTasks('Agreement Sent');
        Test.stopTest();

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Closed', o.StageName);
    }

    @IsTest
    static void test_StageMapping_PartnerReferring_to_Closed() {
        Opportunity o = makeOpp('Partner Referring');
        makeTask(o.Id, 'Meeting Attended', 'Not Started');

        Test.startTest();
        BdAffinityMigrationTool.SetSpecifiedApTasks('Meeting Attended');
        Test.stopTest();

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Closed', o.StageName);
    }

    @IsTest
    static void test_StageMapping_ClosedNotTakenUp_to_Closed() {
        Opportunity o = makeOpp('Closed - Not Taken Up');
        makeTask(o.Id, 'Discovery Call', 'Not Started');

        Test.startTest();
        BdAffinityMigrationTool.SetSpecifiedApTasks('Discovery Call');
        Test.stopTest();

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Closed', o.StageName);
    }

}