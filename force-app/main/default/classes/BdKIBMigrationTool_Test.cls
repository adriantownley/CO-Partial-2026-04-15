@IsTest
private class BdKIBMigrationTool_Test {

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
            Name                   = 'KIB Opp - ' + oldStage + ' - ' + System.currentTimeMillis(),
            RecordTypeId           = partnerRtId(),
            StageName              = 'Qualification',          // per your requirement
            CloseDate              = Date.today().addDays(30),
            Product_Type__c        = 'Group Insurance',        // matches the class filter
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

    // =================
    // Positive Scenarios
    // =================

    @IsTest
    static void testKRIProposalFormSent_Completes_Only_For_GettingAgreementSigned() {
        // Positive
        Opportunity o1 = makeOpp('Getting Agreement Signed');
        Task t1 = makeTask(o1.Id, 'KRI proposal form sent', 'Not Started');

        // Negative sample
        Opportunity o2 = makeOpp('Sending Quote/Proposal');
        Task t2 = makeTask(o2.Id, 'KRI proposal form sent', 'Not Started');

        Test.startTest();
        BdKIBMigrationTool.SetSpecifiedApTasks('KRI proposal form sent');
        Test.stopTest();

        t1 = [SELECT Status FROM Task WHERE Id = :t1.Id];
        t2 = [SELECT Status FROM Task WHERE Id = :t2.Id];

        System.assertEquals('Completed', t1.Status, 'Should complete at Getting Agreement Signed');
        System.assertNotEquals('Completed', t2.Status, 'Should NOT complete at Sending Quote/Proposal');

        o1 = [SELECT StageName FROM Opportunity WHERE Id = :o1.Id];
        o2 = [SELECT StageName FROM Opportunity WHERE Id = :o2.Id];

        System.assertEquals('Implementation', o1.StageName);
        System.assertEquals('Negotiation',  o2.StageName);
    }

    // =================
    // Negative Scenarios
    // =================

    @IsTest
    static void testKRIProposalFormSent_DoesNotComplete_At_NonSignedStages() {
        // Should NOT complete at other stages like Sending Quote/Proposal or Policy Sold
        Opportunity o1 = makeOpp('Sending Quote/Proposal');
        Task t1 = makeTask(o1.Id, 'KRI proposal form sent', 'Not Started');

        Opportunity o2 = makeOpp('Policy Sold');
        Task t2 = makeTask(o2.Id, 'KRI proposal form sent', 'Not Started');

        Test.startTest();
        BdKIBMigrationTool.SetSpecifiedApTasks('KRI proposal form sent');
        Test.stopTest();

        t1 = [SELECT Status FROM Task WHERE Id = :t1.Id];
        t2 = [SELECT Status FROM Task WHERE Id = :t2.Id];

        System.assertNotEquals('Completed', t1.Status, 'Should NOT complete at Sending Quote/Proposal');
        System.assertNotEquals('Completed', t2.Status, 'Should NOT complete at Policy Sold');

        o1 = [SELECT StageName FROM Opportunity WHERE Id = :o1.Id];
        o2 = [SELECT StageName FROM Opportunity WHERE Id = :o2.Id];

        System.assertEquals('Negotiation', o1.StageName);
        System.assertEquals('Closed',      o2.StageName);
    }


    // ==========================
    // Exclusion / No-Data Safety
    // ==========================

    @IsTest
    static void testIgnoresBlankOldStage_NoChange() {
        // Excluded by SOQL: Migration_Old_Stage__c != ''
        Opportunity o = new Opportunity(
            Name                   = 'KIB Opp - Blank Old Stage - ' + System.currentTimeMillis(),
            RecordTypeId           = partnerRtId(),
            StageName              = 'Qualification',
            CloseDate              = Date.today().addDays(30),
            Product_Type__c        = 'Group Insurance',
            Migration_Old_Stage__c = '' // excluded
        );
        insert o;

        Task t = makeTask(o.Id, 'Introduced to KRI', 'Not Started');

        Test.startTest();
        BdKIBMigrationTool.SetSpecifiedApTasks('Introduced to KRI');
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
        BdKIBMigrationTool.SetSpecifiedApTasks('Discovery Call');
        Test.stopTest();

        System.assert(true, 'Method should be safe when no Opportunities match.');
    }
}