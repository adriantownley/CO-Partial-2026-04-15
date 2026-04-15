@IsTest
private class SlaTimeCalculatorTest {

    
    private static Id fetchKingsbridgeBhId() {
        Id bhId = SlaTimeCalculator.getKingsbridgeHours();
        System.assertNotEquals(null, bhId, 'Kingsbridge 8:00 - 5:30 Business Hours must exist in this org for the test.');
        return bhId;
    }

    private static Case makeBaseCase(Id entId, Datetime createdAnchor) {
        Case caseRow = new Case(
            Subject       = 'Kingsbridge SLA Test',
            Status        = 'New',
            Origin        = 'Phone',
            EntitlementId = entId
        );
        insert caseRow;

        Test.setCreatedDate(caseRow.Id, createdAnchor);

        caseRow = [
            SELECT Id, CreatedDate, EntitlementId, Entitlement.BusinessHoursId
            FROM Case
            WHERE Id = :caseRow.Id
        ];
        return caseRow;
    }

    @IsTest
    static void testCalculateTimeWithEntitlementBh() {
        Id bhId = fetchKingsbridgeBhId();

        Auto_Number__c aut = new Auto_Number__c();
        aut.Autonumber_Partner_ID__c = 4445;
        insert aut;

        // Create test Accounts
        Account acc1 = new Account(Name = 'Test Account 1');
        insert acc1;

        Entitlement entRow = new Entitlement(
            Name           = 'Kingsbridge Entitlement',
            Type           = 'Case',
            BusinessHoursId = bhId,
            AccountId = acc1.Id
        );
        insert entRow;

        Datetime createdAnchor = Datetime.newInstance(2025, 1, 6, 10, 0, 0); // Monday 10:00
        Case caseRow = makeBaseCase(entRow.Id, createdAnchor);

        Test.startTest();
        SlaTimeCalculator calcRow = new SlaTimeCalculator();
        Integer minsVal = calcRow.calculateMilestoneTriggerTime(String.valueOf(caseRow.Id), null);
        Test.stopTest();

        Datetime anchorDt = caseRow.CreatedDate;
        Datetime targetDt = SlaTimeCalculator.nextBizDay1730(bhId, anchorDt);

        Long diffMs = BusinessHours.diff(bhId, anchorDt, targetDt);
        Integer expectedMins = 0;
        if (diffMs != null && diffMs > 0) {
            Decimal minsDec = (Decimal)diffMs / (1000 * 60);
            expectedMins = (Integer)Math.ceil(minsDec);
        }

        System.assertNotEquals(0, minsVal, 'Minutes should not be zero for valid case with entitlement BH.');
        System.assertEquals(expectedMins, minsVal, 'Minutes should match rounded-up BusinessHours.diff calculation for entitlement BH.');
    }

    @IsTest
    static void testCalculateTimeWithoutEntitlementBh() {
        Id bhId = fetchKingsbridgeBhId();

        Datetime createdAnchor = Datetime.newInstance(2025, 1, 6, 10, 0, 0); // Monday 10:00
        Case caseRow = makeBaseCase(null, createdAnchor);

        Test.startTest();
        SlaTimeCalculator calcRow = new SlaTimeCalculator();
        Integer minsVal = calcRow.calculateMilestoneTriggerTime(String.valueOf(caseRow.Id), null);
        Test.stopTest();

        
        Datetime anchorDt = caseRow.CreatedDate;
        Datetime targetDt = SlaTimeCalculator.nextBizDay1730(bhId, anchorDt);

        Long diffMs = BusinessHours.diff(bhId, anchorDt, targetDt);
        Integer expectedMins = 0;
        if (diffMs != null && diffMs > 0) {
            Decimal minsDec = (Decimal)diffMs / (1000 * 60);
            expectedMins = (Integer)Math.ceil(minsDec);
        }

        System.assertNotEquals(0, minsVal, 'Minutes should not be zero when fallback BH is used.');
        System.assertEquals(expectedMins, minsVal, 'Minutes should match rounded-up BusinessHours.diff with fallback BH.');
    }
}