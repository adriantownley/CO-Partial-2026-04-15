public class BdProfIndemMigrationTool {


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



 	public static void SetSpecifiedApTasks(string RequestedTaskSubject, string RequestedOldStage)
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
                	WHERE 	(RecordTypeId = :IPRecTypeId) AND (Product_Type__c = 'Professional Indemnity') AND (Migration_Old_Stage__c = :RequestedOldStage)
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
                            
				   			when 'Discovery Call' {
                                
								// This additional Switch Statement is only required for splitting and reducing the number of updates to avoid blowing up Action Plan triggers                                
                                switch on RequestedOldStage {
                                
                                	when 'Booking Meeting' {
                                    	RequestedOppTask.Status = 'Completed';
 			                			BdTasksToUpdate.add(RequestedOppTask);
			                			system.debug('BdTasksToUpdate = ' + BdTasksToUpdate);
                                    }

                                	when 'Completing Meeting' {
                                    	RequestedOppTask.Status = 'Completed';
 			                			BdTasksToUpdate.add(RequestedOppTask);
			                			system.debug('BdTasksToUpdate = ' + BdTasksToUpdate);
                                    }

                                	when 'Implementing Partnership' {
                                    	RequestedOppTask.Status = 'Completed';
 			                			BdTasksToUpdate.add(RequestedOppTask);
			                			system.debug('BdTasksToUpdate = ' + BdTasksToUpdate);
                                    }

                                    
                                }
                            }
                            
				   			when 'Meeting Booked' {
                                If	(	(opp.Migration_Old_Stage__c == 'Completing Meeting') 						||  
                              			(opp.Migration_Old_Stage__c == 'Implementing Partnership')
                                    )
                                {
	                   				RequestedOppTask.Status = 'Completed';
 			                		BdTasksToUpdate.add(RequestedOppTask);
			                		system.debug('BdTasksToUpdate = ' + BdTasksToUpdate);
                                }
                            }
                            
				   			when 'Meeting Attended', 'Agreement Sent', 'Agreement Signed' {
                                If	(opp.Migration_Old_Stage__c == 'Implementing Partnership')
                                {
	                   				RequestedOppTask.Status = 'Completed';
 			                		BdTasksToUpdate.add(RequestedOppTask);
			                		system.debug('BdTasksToUpdate = ' + BdTasksToUpdate);
                                }
                            }
                            
                        }   
                        
						//Then, set the New Opp Stage according to the Old Opp Stage
                       	switch on opp.Migration_Old_Stage__c {
                            
				   			when 'Working out decision maker', 'Booking Meeting' {
				       			System.debug('Migration_Old_Stage__c Switch = ' + opp.Migration_Old_Stage__c);
                            	opp.StageName = 'Qualification';
				   			}
                     	
				   			when 'Completing Meeting' {
				       			System.debug('Migration_Old_Stage__c Switch = ' + opp.Migration_Old_Stage__c);
                            	opp.StageName = 'Negotiation';
				   			}
                     	
				   			when 'Implementing Partnership' {
				       			System.debug('Migration_Old_Stage__c Switch = ' + opp.Migration_Old_Stage__c);
                            	opp.StageName = 'Implementation';
				   			}
                     	
				   			when 'PI Process Implemented', 'Closed Lost' {
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