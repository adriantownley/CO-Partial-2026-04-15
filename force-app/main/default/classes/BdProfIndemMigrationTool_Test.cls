@IsTest
private class BdProfIndemMigrationTool_Test {

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
    // Product_Type__c for this tool: 'Professional Indemnity'
    private static Opportunity makeOpp(String oldStage) {
        Opportunity o = new Opportunity(
            Name                   = 'OPP - ' + oldStage + ' - ' + System.currentTimeMillis(),
            RecordTypeId           = partnerRtId(),
            StageName              = 'Qualification',
            CloseDate              = Date.today().addDays(30),
            Product_Type__c        = 'Professional Indemnity',
            Migration_Old_Stage__c = oldStage
        );
        insert o;
        return o;
    }

    // Create a single Task
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

    // ⚠️ Important: attach one Task for **every possible subject** to every Opportunity
    private static Map<String, Id> makeAllSubjectTasks(Id oppId, String defaultStatus) {
        Map<String, Id> bySubject = new Map<String, Id>();
        List<String> subjects = new List<String>{
            'Discovery Call',
            'Meeting Booked',
            'Meeting Attended',
            'Agreement Sent',
            'Agreement Signed'
        };
        List<Task> toInsert = new List<Task>();
        for (String subj : subjects) {
            toInsert.add(new Task(
                WhatId   = oppId,
                Subject  = subj,
                Status   = defaultStatus,
                Priority = 'Normal'
            ));
        }
        insert toInsert;
        for (Task t : toInsert) {
            bySubject.put(t.Subject, t.Id);
        }
        return bySubject;
    }

    // ================
    // Positive Scenarios
    // ================

    @IsTest
    static void testMeetingBooked_Completes_For_CompletingMeeting() {
        Opportunity o = makeOpp('Completing Meeting');
        Map<String, Id> tasks = makeAllSubjectTasks(o.Id, 'Not Started');

        Test.startTest();
        BdProfIndemMigrationTool.SetSpecifiedApTasks('Meeting Booked', 'Completing Meeting');
        Test.stopTest();

        Task t = [SELECT Status FROM Task WHERE Id = :tasks.get('Meeting Booked')];
        System.assertEquals('Completed', t.Status,
            'Meeting Booked should complete at Completing Meeting');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Negotiation', o.StageName,
            'Completing Meeting should map to Negotiation');
    }

    @IsTest
    static void testAgreementSigned_Completes_For_ImplementingPartnership() {
        Opportunity o = makeOpp('Implementing Partnership');
        Map<String, Id> tasks = makeAllSubjectTasks(o.Id, 'Not Started');

        Test.startTest();
        BdProfIndemMigrationTool.SetSpecifiedApTasks('Agreement Signed', 'Implementing Partnership');
        Test.stopTest();

        Task t = [SELECT Status FROM Task WHERE Id = :tasks.get('Agreement Signed')];
        System.assertEquals('Completed', t.Status,
            'Agreement Signed should complete at Implementing Partnership');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Implementation', o.StageName,
            'Implementing Partnership should map to Implementation');
    }

    // ================
    // Negative Scenarios
    // ================

    @IsTest
    static void testDiscoveryCall_DoesNotComplete_For_WorkingOutDecisionMaker() {
        Opportunity o = makeOpp('Working out decision maker'); // maps to Qualification
        Map<String, Id> tasks = makeAllSubjectTasks(o.Id, 'Not Started');

        Test.startTest();
        BdProfIndemMigrationTool.SetSpecifiedApTasks('Discovery Call', 'Working out decision maker');
        Test.stopTest();

        Task t = [SELECT Status FROM Task WHERE Id = :tasks.get('Discovery Call')];
        System.assertNotEquals('Completed', t.Status,
            'Discovery Call should NOT complete at Working out decision maker');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Qualification', o.StageName,
            'Working out decision maker should map to Qualification');
    }

    @IsTest
    static void testAgreementSigned_DoesNotComplete_UnlessImplementing() {
        Opportunity o = makeOpp('Completing Meeting'); // only Implementing Partnership should complete
        Map<String, Id> tasks = makeAllSubjectTasks(o.Id, 'Not Started');

        Test.startTest();
        BdProfIndemMigrationTool.SetSpecifiedApTasks('Agreement Signed', 'Completing Meeting');
        Test.stopTest();

        Task t = [SELECT Status FROM Task WHERE Id = :tasks.get('Agreement Signed')];
        System.assertNotEquals('Completed', t.Status,
            'Agreement Signed should NOT complete at Completing Meeting');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Negotiation', o.StageName,
            'Completing Meeting should map to Negotiation');
    }

    // =================
    // Stage Mapping Only
    // =================

    @IsTest
    static void testStageMapping_PIProcessImplemented_To_Closed() {
        Opportunity o = makeOpp('PI Process Implemented');
        Map<String, Id> tasks = makeAllSubjectTasks(o.Id, 'Not Started');

        Test.startTest();
        BdProfIndemMigrationTool.SetSpecifiedApTasks('Agreement Signed', 'PI Process Implemented');
        Test.stopTest();

        Task t = [SELECT Status FROM Task WHERE Id = :tasks.get('Agreement Signed')];
        System.assertEquals('Not Started', t.Status,
            'No tasks should complete at PI Process Implemented for Agreement Signed');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Closed', o.StageName,
            'PI Process Implemented should map to Closed');
    }

    @IsTest
    static void testStageMapping_ClosedLost_To_Closed() {
        Opportunity o = makeOpp('Closed Lost');
        Map<String, Id> tasks = makeAllSubjectTasks(o.Id, 'Not Started');

        Test.startTest();
        BdProfIndemMigrationTool.SetSpecifiedApTasks('Meeting Attended', 'Closed Lost');
        Test.stopTest();

        Task t = [SELECT Status FROM Task WHERE Id = :tasks.get('Meeting Attended')];
        System.assertEquals('Not Started', t.Status,
            'No tasks should complete at Closed Lost for Meeting Attended');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Closed', o.StageName,
            'Closed Lost should map to Closed');
    }

    // ==========================
    // Exclusion / No-Data Safety
    // ==========================

    @IsTest
    static void testIgnoresDifferentProduct_NoChange() {
        // SUT filters Product_Type__c = 'Professional Indemnity'
        Opportunity o = new Opportunity(
            Name                   = 'OPP - Wrong Product - ' + System.currentTimeMillis(),
            RecordTypeId           = partnerRtId(),
            StageName              = 'Qualification',
            CloseDate              = Date.today().addDays(30),
            Product_Type__c        = 'Off Payroll Protect', // excluded
            Migration_Old_Stage__c = 'Booking Meeting'
        );
        insert o;

        // Still attach all subject tasks (keeps SUT happy if it ever queried differently)
        Map<String, Id> tasks = makeAllSubjectTasks(o.Id, 'Not Started');

        Test.startTest();
        BdProfIndemMigrationTool.SetSpecifiedApTasks('Discovery Call', 'Booking Meeting');
        Test.stopTest();

        // Should remain unchanged (Opp excluded by product filter)
        Task t = [SELECT Status FROM Task WHERE Id = :tasks.get('Discovery Call')];
        System.assertEquals('Not Started', t.Status,
            'Task should remain unchanged for excluded Product_Type__c');

        o = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Qualification', o.StageName,
            'Stage should remain unchanged for excluded Product_Type__c');
    }

    @IsTest
    static void testNoMatchingOpps_Safe() {
        // No Opps for this RequestedOldStage -> method should not throw
        Test.startTest();
        BdProfIndemMigrationTool.SetSpecifiedApTasks('Discovery Call', 'Non-Existent Old Stage');
        Test.stopTest();

        System.assert(true, 'Method should be safe when no Opportunities match.');
    }
}