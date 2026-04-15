public with sharing class OpportunityTriggerHandler {
    public static void checkDuplicateOpportunities(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();

        for (Opportunity opp : newList) {
            if (opp.AccountId == null) continue;

            Boolean isProductTypeChanged = oldMap == null || (oldMap.containsKey(opp.Id) &&  opp.Product_Type__c != oldMap.get(opp.Id).Product_Type__c);

            // Run logic only on insert OR product type change
            if (oldMap == null || isProductTypeChanged) {
                if (!String.isBlank(opp.Product_Type__c)) {
                    accountIds.add(opp.AccountId);
                    oppMap.put(opp.Id, opp);
                }
            }
        }

        if (accountIds.isEmpty() || oppMap.isEmpty()) return;

        // Query relevant Opportunities first (Closed Lost < 30 days)
        List<Opportunity> existingOpps = [SELECT Id, AccountId, Product_Type__c, Days_since_Closed_Lost__c
                                          FROM Opportunity
                                          WHERE AccountId IN :accountIds
                                          AND StageName = 'Closed Lost'
                                          AND Days_since_Closed_Lost__c < 30];
        system.debug('***existingOpps = ' + existingOpps);

        List<Duplicate_Opportunity_Check__e> eventsToPublish = new List<Duplicate_Opportunity_Check__e>();

        for (Opportunity newOpp : oppMap.values()) {
            // Split the triggering Opportunity's Product Types
            Set<String> newProducts = new Set<String>();
            for (String val : newOpp.Product_Type__c.split(';')) {
                newProducts.add(val.trim());
            }

            // Look for a matching existing Opportunity
            for (Opportunity oldOpp : existingOpps) {
                if (oldOpp.AccountId != newOpp.AccountId) continue;
                if (String.isBlank(oldOpp.Product_Type__c)) continue;

                Set<String> oldProducts = new Set<String>();
                for (String val : oldOpp.Product_Type__c.split(';')) {
                    oldProducts.add(val.trim());
                }

                // Check if there's any overlap between Product Types
                Set<String> common = newProducts.clone();
                common.retainAll(oldProducts);

                if (!common.isEmpty()) {
                    eventsToPublish.add(new Duplicate_Opportunity_Check__e(
                        Matched_Opportunity__c = oldOpp.Id,
                        Triggering_Opportunity__c = newOpp.Id
                    ));
                    break; 
                }
            }
        }

        if (!eventsToPublish.isEmpty()) {
            List<Database.SaveResult> results = EventBus.publish(eventsToPublish);
            system.debug('***save results = ' + results);
        }
    }
}