trigger CaseSlaTrigger on Case (before insert) {

    Id bhId = SlaTimeCalculator.getKingsbridgeHours();
    Datetime anchor = System.now();

    Map<String, Id> rtMap = new Map<String, Id>();
    for (RecordType rt : [
        SELECT Id, DeveloperName 
        FROM RecordType 
        WHERE SObjectType = 'Case'
          AND DeveloperName IN (
              'Complaint',
              'Claims',
              'Customer_Support',
              'Implementation',
              'Missed_Failed_Payment',
              'Renewals',
              'Sales',
              'Underwriting'
          )
    ]) {
        rtMap.put(rt.DeveloperName, rt.Id);
    }

    Id rtComplaint   = rtMap.get('Complaint');
    Id rtClaims      = rtMap.get('Claims');

    Set<Id> nextBizDayRts = new Set<Id>{
        rtMap.get('Customer_Support'),
        rtMap.get('Implementation'),
        rtMap.get('Missed_Failed_Payment'),
        rtMap.get('Renewals'),
        rtMap.get('Sales'),
        rtMap.get('Underwriting')
    };

    for (Case c : Trigger.new) {

        if (c.RecordTypeId == rtComplaint) {

            c.First_Response_SLA__c =
                BusinessHours.add(bhId, anchor, 2850L * 60 * 1000);

        } else if (c.RecordTypeId == rtClaims) {

            c.First_Response_SLA__c =
                BusinessHours.add(bhId, anchor, 510L * 60 * 1000);

        } else if (nextBizDayRts.contains(c.RecordTypeId)) {

            c.First_Response_SLA__c =
                SlaTimeCalculator.nextBizDay1730(bhId, anchor);

        } else {
            
            c.First_Response_SLA__c =
                SlaTimeCalculator.nextBizDay1730(bhId, anchor);
        }
    }
}