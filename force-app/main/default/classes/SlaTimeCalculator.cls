global with sharing class SlaTimeCalculator implements Support.MilestoneTriggerTimeCalculator {

    global static Id getKingsbridgeHours() {
        BusinessHours bh = [
            SELECT Id
            FROM BusinessHours
            WHERE Name = 'Kingsbridge 8:00 - 5:30'
            LIMIT 1
        ];
        return bh.Id;
    }

    global static Datetime nextBizDay1730(Id bhId, Datetime anchorDt) {
        // Move to tomorrow
        Date probeDate = anchorDt.date().addDays(1);

        // Check midday on that date to ensure it's a business day
        Datetime probeMidday = Datetime.newInstance(
            probeDate,
            Time.newInstance(12, 0, 0, 0)
        );

        // Salesforce will roll to the next valid business day if needed
        Datetime nextOpen = BusinessHours.nextStartDate(bhId, probeMidday);
        Date targetDate = nextOpen.date();

        // Desired target time: 17:30
        Time targetTime = Time.newInstance(17, 30, 0, 0);
        Datetime targetDt = Datetime.newInstance(targetDate, targetTime);

        return targetDt;
    }

    global Integer calculateMilestoneTriggerTime(String caseIdTxt, String milestoneTypeIdTxt) {

        if (String.isBlank(caseIdTxt)) {
            return 0;
        }

        Id caseIdRow;

        try {
            caseIdRow = Id.valueOf(caseIdTxt);
        } catch (Exception e) {
            return 0;
        }

        try {
            Case casRow = [
                SELECT Id, CreatedDate, Entitlement.BusinessHoursId
                FROM Case
                WHERE Id = :caseIdRow
                LIMIT 1
            ];

            Id bhId = casRow.Entitlement != null
                ? casRow.Entitlement.BusinessHoursId
                : null;

            if (bhId == null) {
                bhId = getKingsbridgeHours();
            }

            Datetime anchorDt = casRow.CreatedDate;
            Datetime targetDt = nextBizDay1730(bhId, anchorDt);

            Long diffMs = BusinessHours.diff(bhId, anchorDt, targetDt);
            if (diffMs == null || diffMs <= 0) {
                return 0;
            }

            
            Decimal minsDec = (Decimal)diffMs / (1000 * 60); 
            Integer minsToTarget = (Integer)Math.ceil(minsDec);

            return minsToTarget;

        } catch (Exception e2) {
            return 0;
        }
    }
}