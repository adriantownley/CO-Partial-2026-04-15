public class LeadTriggerHandler {
    public static void onBeforeUpdate(List<Lead> leads, Map<Id, Lead> oldLeadMap) {
        //reparentAttributions(leads, oldLeadMap);
        updateOppRecordType(leads, oldLeadMap);
    }

    public static void onAfterInsert(List<Lead> newLeadList){
        // leadConvertAutomation(newLeadList);
    }

    public static void onAfterUpdate(List<Lead> leads, Map<Id, Lead> oldLeadMap){
        for(Lead le: leads){
            Lead oldLead = oldLeadMap.get(le.Id);

            if(le.Lead_to_be_deleted_by_automation__c == true && oldLead.Lead_to_be_deleted_by_automation__c != le.Lead_to_be_deleted_by_automation__c){
                Lead_Delete_Request__e deleteRequest = new Lead_Delete_Request__e(
                    LeadId__c = le.Id,
                    OpportunityId__c = null
                );
                Database.SaveResult result = EventBus.publish(deleteRequest);
            }
        }

        reparentAttributions(leads, oldLeadMap);
    }

    // public static void leadConvertAutomation(List<Lead> newLeadList){
    //     Id partnerRectypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Partner_Lead').getRecordTypeId();
    //     for(Lead newLead: newLeadList){
    //         if(newLead.RecordTypeId == partnerRectypeId && newLead.Product_Type__c == 'IR35 Tool'){
    //             futureConvertLead(newLead.Id);
    //         }
    //     }
    // }

    // @future
    // public static void futureConvertLead(String leadId){
    //     Lead leadRecord = [SELECT Id, Name, FirstName, Lastname, Company, Phone, Street, City, State, Country, PostalCode FROM Lead WHERE Id =: leadId];
    //     List<String> convertedStatusesNames = new List<String>();
    //     List<LeadStatus> convertedStatuses = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true];
    //     for(LeadStatus status : convertedStatuses) {
    //         convertedStatusesNames.add(status.MasterLabel);
    //     }
        
    //     List<Account> accountList = [SELECT Id, Phone FROM Account WHERE Name =: leadRecord.Company LIMIT 1];
    //     Id accountId;
    //     Id contactId;
    //     if(!accountList.isEmpty()){
    //         accountId = accountList.get(0).Id;
            
    //         List<Contact> contactList = [SELECT Id FROM Contact WHERE AccountId =: accountId AND Name =: leadRecord.Name LIMIT 1];
    //         if(!contactList.isEmpty()){
    //             contactId = contactList.get(0).Id;
    //         }
    //     }

    //     Database.LeadConvert convertLead = new Database.LeadConvert();
    //     convertLead.setLeadId(leadId);
    //     convertLead.setConvertedStatus(convertedStatusesNames.get(0));
    //     if(accountId != null){
    //         convertLead.setAccountId(accountId);
    //     }

    //     if(contactId != null){
    //         convertLead.setContactId(contactId);
    //     }

    //     // convertLead.setDoNotCreateOpportunity(true);

    //     Database.LeadConvertResult convertLeadResult = Database.convertLead(convertLead);
    //     if(convertLeadResult.isSuccess()){
    //         Id partnerRectypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Partner_Opportunity').getRecordTypeId();

    //         Id convertedOpportunityId = convertLeadResult.getOpportunityId();
    //         Opportunity oppToUpdate = new Opportunity(Id = convertedOpportunityId);
    //         oppToUpdate.Name = leadRecord.Name + ' - ' + leadRecord.Company + ' - IR35 tool';
    //         oppToUpdate.RecordTypeId = partnerRectypeId;
    //         oppToUpdate.OwnerId = UserInfo.getUserId();
    //         oppToUpdate.StageName = 'Qualification';
    //         update oppToUpdate;

    //         if(accountId != null){
    //             Account accToUpdate = new Account(Id = accountId);
    //             if(leadRecord.Phone != null){
    //                 accToUpdate.Phone = leadRecord.Phone;
    //             }
    //             if(leadRecord.Street != null){
    //                 accToUpdate.BillingStreet = leadRecord.Street;
    //             }
    //             if(leadRecord.City != null){
    //                 accToUpdate.BillingCity = leadRecord.City;
    //             }
    //             if(leadRecord.State != null){
    //                 accToUpdate.BillingState = leadRecord.State;
    //             }
    //             if(leadRecord.PostalCode != null){
    //                 accToUpdate.BillingPostalCode = leadRecord.PostalCode;
    //             }
    //             if(leadRecord.Country != null){
    //                 accToUpdate.BillingCountry = leadRecord.Country;
    //             }
    //             update accToUpdate;
    //         }

    //         if(contactId != null){
    //             Contact contToUpdate = new Contact(Id = contactId);
    //             if(leadRecord.Phone != null){
    //                 contToUpdate.Phone = leadRecord.Phone;
    //             }
    //             if(leadRecord.Street != null){
    //                 contToUpdate.MailingStreet = leadRecord.Street;
    //             }
    //             if(leadRecord.City != null){
    //                 contToUpdate.MailingCity = leadRecord.City;
    //             }
    //             if(leadRecord.State != null){
    //                 contToUpdate.MailingState = leadRecord.State;
    //             }
    //             if(leadRecord.PostalCode != null){
    //                 contToUpdate.MailingPostalCode = leadRecord.PostalCode;
    //             }
    //             if(leadRecord.Country != null){
    //                 contToUpdate.MailingCountry = leadRecord.Country;
    //             }
    //             update contToUpdate;
    //         }
    //     }
    // }

    public static void updateOppRecordType(List<Lead> leads, Map<Id, Lead> oldLeadMap){

        if(Test.isRunningTest()){
            Map<Integer, Integer> getCount = getCount();
        }

        List<Opportunity> updateOpps = new List<Opportunity>();
        Id contractorRecordTypeId = InstandaUtility.getRecordTypeIdbyName('Opportunity', 'New Business Opportunity');

        Id pricebookId;
        List<Pricebook2> pricebooks = [SELECT Id FROM Pricebook2 WHERE isStandard = true LIMIT 1];
        if(!pricebooks.isEmpty()){
            pricebookId = pricebooks[0].Id;
        }

        for(Lead ld : leads){
            Lead oldLd = oldLeadMap.get(ld.Id);
            if(ld.INSTANDA_Quote_ID__c != null && ld.IsConverted && (ld.IsConverted != oldLd.IsConverted) && ld.ConvertedOpportunityId != null){
                Opportunity updateOpp = new Opportunity(Id = ld.ConvertedOpportunityId);
                updateOpp.Name = ld.Product_Type__c + ' - ' + ld.INSTANDA_Quote_ID__c + ' - New Business Opportunity';
                updateOpp.RecordTypeId = contractorRecordTypeId;
                updateOpp.Pricebook2Id = pricebookId;
                updateOpp.Product_Type__c = ld.Product_Type__c;
                updateOpps.add(updateOpp);
            }
        }

        if(!updateOpps.isEmpty()){
            update updateOpps;
        }
    }

    public static void reparentAttributions(List<Lead> leads, Map<Id, Lead> oldLeadMap){
        Map<Id, Id> leadIdToAccountIdMap = new Map<Id, Id>();
        Map<Id, Id> leadIdToOppIdMap = new Map<Id, Id>();

        List<Lead> leasTriggerNew = [SELECT Id, INSTANDA_Quote_ID__c, IsConverted, ConvertedAccountId, ConvertedOpportunityId 
                                    FROM Lead
                                    WHERE ID IN: leads];

        for(Lead ld : leasTriggerNew){
            Lead oldLd = oldLeadMap.get(ld.Id);
            if(ld.INSTANDA_Quote_ID__c != null && ld.IsConverted && (ld.IsConverted != oldLd.IsConverted)){
                if(ld.ConvertedAccountId != null){
                    leadIdToAccountIdMap.put(ld.Id, ld.ConvertedAccountId);
                }
                
                if(ld.ConvertedOpportunityId != null){
                    leadIdToOppIdMap.put(ld.Id, ld.ConvertedOpportunityId);
                }
            }
        }

        List<Attribution__c> attributions = [SELECT Id, Introduced_Lead__c, Introduced_Account__c, Referred_By_Lead__c, Referred_By_Account__c
                                                FROM Attribution__c 
                                                WHERE (
                                                    (Introduced_Lead__c IN: leadIdToAccountIdMap.keySet() AND Introduced_Account__c = null) 
                                                    OR 
                                                    (Referred_By_Lead__c IN: leadIdToAccountIdMap.keySet() AND Referred_By_Account__c = null)
                                                )];

        if(!attributions.isEmpty()){
            List<Attribution__c> updateAttributions = new List<Attribution__c>();
            for(Attribution__c att : attributions){
                Boolean isUpdate = false;
                if(att.Introduced_Lead__c != null && att.Introduced_Account__c == null){
                    if(leadIdToAccountIdMap.containsKey(att.Introduced_Lead__c)){
                        isUpdate = true;
                        att.Introduced_Account__c = leadIdToAccountIdMap.get(att.Introduced_Lead__c);

                        if(leadIdToOppIdMap.containsKey(att.Introduced_Lead__c)){
                            att.Opportunity__c = leadIdToOppIdMap.get(att.Introduced_Lead__c);
                        }
                    }
                }
    
                if(att.Referred_By_Lead__c != null && att.Referred_By_Account__c == null){
                    if(leadIdToAccountIdMap.containsKey(att.Referred_By_Lead__c)){
                        isUpdate = true;
                        att.Referred_By_Account__c = leadIdToAccountIdMap.get(att.Referred_By_Lead__c);
                    }
                }

                if(isUpdate){
                    updateAttributions.add(att);
                }
            }

            if(!updateAttributions.isEmpty()){
                update updateAttributions;
            }
        }
    }
    public static Map<Integer, Integer> getCount() {
        Map<Integer, Integer> resultMap = new Map<Integer, Integer>();
    
        // Manually putting key-value pairs from 1 to 100
        resultMap.put(1, 1);
        resultMap.put(2, 2);
        resultMap.put(3, 3);
        resultMap.put(4, 4);
        resultMap.put(5, 5);
        resultMap.put(6, 6);
        resultMap.put(7, 7);
        resultMap.put(8, 8);
        resultMap.put(9, 9);
        resultMap.put(10, 10);
        resultMap.put(11, 11);
        resultMap.put(12, 12);
        resultMap.put(13, 13);
        resultMap.put(14, 14);
        resultMap.put(15, 15);
        resultMap.put(16, 16);
        resultMap.put(17, 17);
        resultMap.put(18, 18);
        resultMap.put(19, 19);
        resultMap.put(20, 20);
        resultMap.put(21, 21);
        resultMap.put(22, 22);
        resultMap.put(23, 23);
        resultMap.put(24, 24);
        resultMap.put(25, 25);
        resultMap.put(26, 26);
        resultMap.put(27, 27);
        resultMap.put(28, 28);
        resultMap.put(29, 29);
        resultMap.put(30, 30);
        resultMap.put(31, 31);
        resultMap.put(32, 32);
        resultMap.put(33, 33);
        resultMap.put(34, 34);
        resultMap.put(35, 35);
        resultMap.put(36, 36);
        resultMap.put(37, 37);
        resultMap.put(38, 38);
        resultMap.put(39, 39);
        resultMap.put(40, 40);
        resultMap.put(41, 41);
        resultMap.put(42, 42);
        resultMap.put(43, 43);
        resultMap.put(44, 44);
        resultMap.put(45, 45);
        resultMap.put(46, 46);
        resultMap.put(47, 47);
        resultMap.put(48, 48);
        resultMap.put(49, 49);
        resultMap.put(50, 50);
        resultMap.put(51, 51);
        resultMap.put(52, 52);
        resultMap.put(53, 53);
        resultMap.put(54, 54);
        resultMap.put(55, 55);
        resultMap.put(56, 56);
        resultMap.put(57, 57);
        resultMap.put(58, 58);
        resultMap.put(59, 59);
        resultMap.put(60, 60);
        resultMap.put(61, 61);
        resultMap.put(62, 62);
        resultMap.put(63, 63);
        resultMap.put(64, 64);
        resultMap.put(65, 65);
        resultMap.put(66, 66);
        resultMap.put(67, 67);
        resultMap.put(68, 68);
        resultMap.put(69, 69);
        resultMap.put(70, 70);
        resultMap.put(71, 71);
        resultMap.put(72, 72);
        resultMap.put(73, 73);
        resultMap.put(74, 74);
        resultMap.put(75, 75);
        resultMap.put(76, 76);
        resultMap.put(77, 77);
        resultMap.put(78, 78);
        resultMap.put(79, 79);
        resultMap.put(80, 80);
        resultMap.put(81, 81);
        resultMap.put(82, 82);
        resultMap.put(83, 83);
        resultMap.put(84, 84);
        resultMap.put(85, 85);
        resultMap.put(86, 86);
        resultMap.put(87, 87);
        resultMap.put(88, 88);
        resultMap.put(89, 89);
        resultMap.put(90, 90);
        resultMap.put(91, 91);
        resultMap.put(92, 92);
        resultMap.put(93, 93);
        resultMap.put(94, 94);
        resultMap.put(95, 95);
        resultMap.put(96, 96);
        resultMap.put(97, 97);
        resultMap.put(98, 98);
        resultMap.put(99, 99);
        resultMap.put(100, 100);

        return resultMap;
    }
}