public class BdKIBMigrationTool {


    public static Id 									IPRecTypeId;
	public static List<Opportunity> 					BdOppsList 		= new List<Opportunity>();
	public static List<Task> 							BdTasksList 	= new List<Task>();
    public static List<LabsActionPlans__ActionPlan__c> 	ApPlansList 	= new List<LabsActionPlans__ActionPlan__c>();
    public static List<LabsActionPlans__APTask__c> 		ApTasksList 	= new List<LabsActionPlans__APTask__c>();
	public static Map<Id,LabsActionPlans__APTask__c> 	ApTasksMap 		= new Map<Id,LabsActionPlans__APTask__c>();
	public static List<Opportunity> 					BdOppsToUpdate 	= new List<Opportunity>();
    public static List<Task> 							BdTasksToUpdate = new List<Task>();
    public static List<LabsActionPlans__APTask__c> 		APTasksToUpdate = new List<LabsActionPlans__APTask__c>();
    public static LabsActionPlans__APTask__c 			CurrentAPTask;
    public static Task 									RequestedOppTask;



 	public static void SetSpecifiedApTasks(string RequestedTaskSubject)
    {



    	// Return Partner_Opportunity record type Id by DeveloperName
		IPRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Partner_Opportunity').getRecordTypeId();
		System.debug('MyRecTypeId = ' + IPRecTypeId);

		BdOppsList = 
           	[	SELECT 	Id,
               			name, 
               			(SELECT Id, Subject, Status, LabsActionPlans__TaskAPTask__c from Tasks),
               			StageName,
                   		Type,
               			OwnerId,
               			CloseDate,
               			Product_Type__c,
               			Migration_Old_Stage__c
       		  	FROM 	Opportunity 
                	WHERE 	(RecordTypeId = :IPRecTypeId) AND (Product_Type__c = 'Group Insurance') AND (Migration_Old_Stage__c != '')
            	];
        
		System.debug('Number of Opps Found - ' + BdOppsList.size());
            

       If (BdOppsList.size() > 0){
            
        	for (Opportunity opp : BdOppsList)
        	{
				system.debug('Opp = ' + opp);

                for (Task thisTask :opp.Tasks){
                	system.debug('thisTaskOpp = ' + thisTask);
                    If (thisTask.Subject == RequestedTaskSubject) {
                        RequestedOppTask = thisTask;
					}
				}
                        
                     

                // First Set the requested Task to completed depending on the Old Opp Stage
                       	switch on RequestedTaskSubject {
                            
				   			when 'Discovery Call', 'Introduced to KRI' {
                                If	(	(opp.Migration_Old_Stage__c == 'Completing Proposal Form') 				||
                              			(opp.Migration_Old_Stage__c == 'Sending Quote/Proposal') 			||  
                              			(opp.Migration_Old_Stage__c == 'Getting Agreement Signed')
                                    )
                                
                                {
	                   				RequestedOppTask.Status = 'Completed';
 			                		BdTasksToUpdate.add(RequestedOppTask);
			                		system.debug('RequestedOppTask = ' + RequestedOppTask);
                                }
                            }
                            
				   			when 'KRI proposal form sent' {
                                If	(opp.Migration_Old_Stage__c == 'Getting Agreement Signed')
                                {
	                   				RequestedOppTask.Status = 'Completed';
 			                		BdTasksToUpdate.add(RequestedOppTask);
			                		system.debug('RequestedOppTask = ' + RequestedOppTask);
                                }
                            }
                            
                        }
                        
						//Then, set the New Opp Stage according to the Old Opp Stage
                       	switch on opp.Migration_Old_Stage__c {
                            
				   			when 'Working out decision maker', 'Logging Renewal Date' {
				       			System.debug('Migration_Old_Stage__c Switch = ' + opp.Migration_Old_Stage__c);
                            	opp.StageName = 'Qualification';
				   			}
                     	
				   			when 'Completing Proposal Form', 'Sending Quote/Proposal' {
				       			System.debug('Migration_Old_Stage__c Switch = ' + opp.Migration_Old_Stage__c);
                            	opp.StageName = 'Negotiation';
				   			}
                     	
				   			when 'Getting Agreement Signed' {
				       			System.debug('Migration_Old_Stage__c Switch = ' + opp.Migration_Old_Stage__c);
                            	opp.StageName = 'Implementation';
				   			}
                     	
				   			when 'Closed Lost', 'Policy Sold' {
				       			System.debug('Migration_Old_Stage__c Switch = ' + opp.Migration_Old_Stage__c);
                            	opp.StageName = 'Closed';
				   			}
                     	
				   		}
                       	BdOppsToUpdate.add(opp);

                	}
                    


            
        }
        Else{
	      	system.debug('Export Failed! No Opps To Extract!');
        }
          
   	try	{
			update BdOppsToUpdate;
			update BdTasksToUpdate;
		} 
		catch(DmlException e) 
        {
        	system.debug('Error - ' + e);            
        }

    }
    
        

    
}