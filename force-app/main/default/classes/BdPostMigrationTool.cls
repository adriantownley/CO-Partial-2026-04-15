public class BdPostMigrationTool {

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



 	public static void SetSpecifiedApTasks(string ProductType, string RequestedTaskSubject, string RequestedOldStage)
    {



    	// Return Partner_Opportunity record type Id by DeveloperName
		IPRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Partner_Opportunity').getRecordTypeId();
		System.debug('MyRecTypeId = ' + IPRecTypeId);

		If ( (ProductType == 'Professional Indemnity') && (RequestedOldStage != 'WhatEvah!') )
        {
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
                	WHERE 	(RecordTypeId = :IPRecTypeId) AND (Product_Type__c = :ProductType) AND (Migration_Old_Stage__c = :RequestedOldStage)
//                    LIMIT 	100
            	];
        
		System.debug('Number of Opps Found - ' + BdOppsList.size());
        }
        else{
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
                	WHERE 	(RecordTypeId = :IPRecTypeId) AND (Product_Type__c = :ProductType) AND (Migration_Old_Stage__c != '')
//                    LIMIT 	100
            	];
        
		System.debug('Number of Opps Found - ' + BdOppsList.size());
            
        }

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
                        
                     
				switch on ProductType {

                   when 'IR35 Health Check' {
				   		System.debug('ProductType Switch = ' + ProductType);

                        // First Set the requested Task to completed depending on the Old Opp Stage
                       	switch on RequestedTaskSubject {
                            
				   			when 'Discovery Call', 'Health Check IR35 Team Meeting Booked' {
                                If	(	(opp.Migration_Old_Stage__c == 'Meeting Booked') ||
                              			(opp.Migration_Old_Stage__c == 'Meeting Attended') ||  
                              			(opp.Migration_Old_Stage__c == 'Proposal Sent') ||  
                              			(opp.Migration_Old_Stage__c == 'Healthcheck Booked')
                                    )
                                
                                {
	                   				RequestedOppTask.Status = 'Completed';
 			                		BdTasksToUpdate.add(RequestedOppTask);
			                		system.debug('BdTasksToUpdate = ' + BdTasksToUpdate);
                                }
                            }
                            
				   			when 'Health Check IR35 Team Meeting Attended' {
                                If	(opp.Migration_Old_Stage__c == 'Healthcheck Booked')
                                {
	                   				RequestedOppTask.Status = 'Completed';
 			                		BdTasksToUpdate.add(RequestedOppTask);
			                		system.debug('BdTasksToUpdate = ' + BdTasksToUpdate);
                                }
                            }
                            
                        }
                        
						//Then, set the New Opp Stage according to the Old Opp Stage
                        switch on opp.Migration_Old_Stage__c {
                            
				   			when 'Meeting Booked' {
				       			System.debug('Migration_Old_Stage__c Switch = ' + opp.Migration_Old_Stage__c);
                            	opp.StageName = 'Qualification';
				   			}
                     	
				   			when 'Meeting Attended', 'Proposal Sent', 'Healthcheck Booked' {
				       			System.debug('Migration_Old_Stage__c Switch = ' + opp.Migration_Old_Stage__c);
                            	opp.StageName = 'Negotiation';
				   			}
                     	
                     	
				   			when 'Healthcheck Completed', 'Healthcheck Complete', 'Closed - Not Taken Up' {
				       			System.debug('Migration_Old_Stage__c Switch = ' + opp.Migration_Old_Stage__c);
                            	opp.StageName = 'Closed';
				   			}
                     	
				   		}
                       	BdOppsToUpdate.add(opp);

                	}
                    
				   when 'IR35 Tool' {
				   		System.debug('ProductType Switch = ' + ProductType);

                       	switch on RequestedTaskSubject {
                            
				   			when 'Discovery Call', 'Discovery Fact Find Complete' {
                                If	(	(opp.Migration_Old_Stage__c == 'Booking Demo') 				||
                              			(opp.Migration_Old_Stage__c == 'Completing Demo') 			||  
                              			(opp.Migration_Old_Stage__c == 'Sending Quote/Proposal') 	||  
                              			(opp.Migration_Old_Stage__c == 'Sending Agreement') 		||
                              			(opp.Migration_Old_Stage__c == 'Getting Agreement Signed')	//||
//                              			(opp.Migration_Old_Stage__c == 'Tool Sold')
                                    )
                                
                                {
	                   				RequestedOppTask.Status = 'Completed';
 			                		BdTasksToUpdate.add(RequestedOppTask);
			                		system.debug('BdTasksToUpdate = ' + BdTasksToUpdate);
                                }
                            }
                            
				   			when 'Demo Booked' {
                                If	( 	(opp.Migration_Old_Stage__c == 'Completing Demo') 			||  
                              			(opp.Migration_Old_Stage__c == 'Sending Quote/Proposal') 	||  
                              			(opp.Migration_Old_Stage__c == 'Sending Agreement') 		||
                              			(opp.Migration_Old_Stage__c == 'Getting Agreement Signed')	//||
//                              			(opp.Migration_Old_Stage__c == 'Tool Sold')
                                     )
                                {
	                   				RequestedOppTask.Status = 'Completed';
 			                		BdTasksToUpdate.add(RequestedOppTask);
			                		system.debug('BdTasksToUpdate = ' + BdTasksToUpdate);
                                }
                            }
                            
				   			when 'Demo Attended' {
                                If	( 	(opp.Migration_Old_Stage__c == 'Sending Quote/Proposal') 	||  
                              			(opp.Migration_Old_Stage__c == 'Sending Agreement') 		||
                              			(opp.Migration_Old_Stage__c == 'Getting Agreement Signed')	//||
//                              			(opp.Migration_Old_Stage__c == 'Tool Sold')
                                     )
                                {
	                   				RequestedOppTask.Status = 'Completed';
 			                		BdTasksToUpdate.add(RequestedOppTask);
			                		system.debug('BdTasksToUpdate = ' + BdTasksToUpdate);
                                }
                            }
                            
				   			when 'Proposal Sent' {
                                If	( 	(opp.Migration_Old_Stage__c == 'Sending Agreement') 		||
                              			(opp.Migration_Old_Stage__c == 'Getting Agreement Signed')	//||
//                              			(opp.Migration_Old_Stage__c == 'Tool Sold')
                                     )
                                {
	                   				RequestedOppTask.Status = 'Completed';
 			                		BdTasksToUpdate.add(RequestedOppTask);
			                		system.debug('BdTasksToUpdate = ' + BdTasksToUpdate);
                                }
                            }
                            
				   			when 'Agreement Sent' {
                                If	( 	(opp.Migration_Old_Stage__c == 'Getting Agreement Signed')	//||
//                              			(opp.Migration_Old_Stage__c == 'Tool Sold')
                                     )
                                {
	                   				RequestedOppTask.Status = 'Completed';
 			                		BdTasksToUpdate.add(RequestedOppTask);
			                		system.debug('BdTasksToUpdate = ' + BdTasksToUpdate);
                                }
                            }
                            
//				   			when 'Agreement Signed' {
  //                              If	(opp.Migration_Old_Stage__c == 'Tool Sold')
    //                            {
	  //                 				RequestedOppTask.Status = 'Completed';
 		//	                		BdTasksToUpdate.add(RequestedOppTask);
			//                		system.debug('BdTasksToUpdate = ' + BdTasksToUpdate);
              //                  }
                //            }
                            
                        }
                        
                       	switch on opp.Migration_Old_Stage__c {
                            
				   			when 'Working out decision maker', 'Booking Demo' {
				       			System.debug('Migration_Old_Stage__c Switch = ' + opp.Migration_Old_Stage__c);
                            	opp.StageName = 'Qualification';
				   			}
                     	
				   			when 'Completing Demo', 'Sending Quote/Proposal', 'Sending Agreement', 'Getting Agreement Signed' {
				       			System.debug('Migration_Old_Stage__c Switch = ' + opp.Migration_Old_Stage__c);
                            	opp.StageName = 'Negotiation';
				   			}
                     	
//				   			when 'Tool Sold' {
	//			       			System.debug('Migration_Old_Stage__c Switch = ' + opp.Migration_Old_Stage__c);
      //                      	opp.StageName = 'Implementation';
		//		   			}
                     	
                     	
				   			when 'Closed Lost', 'Tool Sold' {
				       			System.debug('Migration_Old_Stage__c Switch = ' + opp.Migration_Old_Stage__c);
                            	opp.StageName = 'Closed';
				   			}
                     	
				   		}
                       	BdOppsToUpdate.add(opp);

				   }
                    
				   when 'Off Payroll Protect' {
				   		System.debug('ProductType Switch = ' + ProductType);

                       	switch on RequestedTaskSubject {
                            
				   			when 'Discovery Call', 'Meeting Booked' {
                                If	(	(opp.Migration_Old_Stage__c == 'Completing Meeting') 				||
                              			(opp.Migration_Old_Stage__c == 'Implementing Off Payroll') 			//||  
//                              			(opp.Migration_Old_Stage__c == 'Off Payroll Protect Sale')
                                    )
                                
                                {
	                   				RequestedOppTask.Status = 'Completed';
 			                		BdTasksToUpdate.add(RequestedOppTask);
			                		system.debug('BdTasksToUpdate = ' + BdTasksToUpdate);
                                }
                            }
                            
				   			when 'Meeting Attended', 'Supply Chain Confirmation' {
                                If	(	(opp.Migration_Old_Stage__c == 'Implementing Off Payroll') 			//||  
//                              			(opp.Migration_Old_Stage__c == 'Off Payroll Protect Sale')
                                    )
                                {
	                   				RequestedOppTask.Status = 'Completed';
 			                		BdTasksToUpdate.add(RequestedOppTask);
			                		system.debug('BdTasksToUpdate = ' + BdTasksToUpdate);
                                }
                            }
                            
				   			when 'Proposal Link Sent', 'Proposal Link Completed', 'Proposal UW Quote Sent' {
                                If	(opp.Migration_Old_Stage__c == 'Off Payroll Protect Sale')
                                {
	                   				RequestedOppTask.Status = 'Completed';
 			                		BdTasksToUpdate.add(RequestedOppTask);
			                		system.debug('BdTasksToUpdate = ' + BdTasksToUpdate);
                                }
                            }
                            
                            
                        }
                        
                       	switch on opp.Migration_Old_Stage__c {
                            
				   			when 'Booking Meeting' {
				       			System.debug('Migration_Old_Stage__c Switch = ' + opp.Migration_Old_Stage__c);
                            	opp.StageName = 'Qualification';
				   			}
                     	
				   			when 'Completing Meeting', 'Implementing Off Payroll' {
				       			System.debug('Migration_Old_Stage__c Switch = ' + opp.Migration_Old_Stage__c);
                            	opp.StageName = 'Negotiation';
				   			}
                     	
//				   			when 'Off Payroll Protect Sale' {
	//			       			System.debug('Migration_Old_Stage__c Switch = ' + opp.Migration_Old_Stage__c);
      //                      	opp.StageName = 'Implementation';
		//		   			}
                     	
				   			when 'Closed - Not Taken Up', 'Off Payroll Protect Sale' {
				       			System.debug('Migration_Old_Stage__c Switch = ' + opp.Migration_Old_Stage__c);
                            	opp.StageName = 'Closed';
				   			}
                     	
				   		}
                       	BdOppsToUpdate.add(opp);

				   }
                    
				   when 'IR35 Protect Insurance' {
				   		System.debug('ProductType Switch = ' + ProductType);

                       	switch on RequestedTaskSubject {
                            
				   			when 'Discovery Call' {
                                If	(	(opp.Migration_Old_Stage__c == 'Booking Meeting') 							||
                              			(opp.Migration_Old_Stage__c == 'Completing Meeting') 						||  
                              			(opp.Migration_Old_Stage__c == 'Inserting Paragraph/IR35 Secure Turned On') //||  
//                              			(opp.Migration_Old_Stage__c == 'IR35 Terms Implemented')
                                    )
                                
                                {
	                   				RequestedOppTask.Status = 'Completed';
 			                		BdTasksToUpdate.add(RequestedOppTask);
			                		system.debug('BdTasksToUpdate = ' + BdTasksToUpdate);
                                }
                            }
                            
				   			when 'Meeting Booked' {
                                If	(	(opp.Migration_Old_Stage__c == 'Completing Meeting') 						||  
                              			(opp.Migration_Old_Stage__c == 'Inserting Paragraph/IR35 Secure Turned On') //||  
//                              			(opp.Migration_Old_Stage__c == 'IR35 Terms Implemented')
                                    )
                                {
	                   				RequestedOppTask.Status = 'Completed';
 			                		BdTasksToUpdate.add(RequestedOppTask);
			                		system.debug('BdTasksToUpdate = ' + BdTasksToUpdate);
                                }
                            }
                            
				   			when 'Meeting Attended' {
                                If	(	(opp.Migration_Old_Stage__c == 'Inserting Paragraph/IR35 Secure Turned On') //||  
//                              			(opp.Migration_Old_Stage__c == 'IR35 Terms Implemented')
                                    )
                                {
	                   				RequestedOppTask.Status = 'Completed';
 			                		BdTasksToUpdate.add(RequestedOppTask);
			                		system.debug('BdTasksToUpdate = ' + BdTasksToUpdate);
                                }
                            }
                        }   
                            
                        
                       	switch on opp.Migration_Old_Stage__c {
                            
				   			when 'Working out decision maker' {
				       			System.debug('Migration_Old_Stage__c Switch = ' + opp.Migration_Old_Stage__c);
                            	opp.StageName = 'Qualification';
				   			}
                     	
				   			when 'Booking Meeting', 'Completing Meeting' {
				       			System.debug('Migration_Old_Stage__c Switch = ' + opp.Migration_Old_Stage__c);
                            	opp.StageName = 'Negotiation';
				   			}
                     	
				   			when 'Inserting Paragraph/IR35 Secure Turned On' {
				       			System.debug('Migration_Old_Stage__c Switch = ' + opp.Migration_Old_Stage__c);
                            	opp.StageName = 'Implementation';
				   			}
                     	
				   			when 'Closed Lost', 'IR35 Terms Implemented' {
				       			System.debug('Migration_Old_Stage__c Switch = ' + opp.Migration_Old_Stage__c);
                            	opp.StageName = 'Closed';
				   			}
                     	
				   		}
                       	BdOppsToUpdate.add(opp);

				   }
                    
				   when 'Group Insurance' {
				   		System.debug('ProductType Switch = ' + ProductType);

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
                    
				   when 'Public Liability Affinity' {
				   		System.debug('ProductType Switch = ' + ProductType);

                       	switch on RequestedTaskSubject {
                            
				   			when 'Discovery Call' {

                                
                                If	(	(opp.Migration_Old_Stage__c == 'Booking Meeting') 							||
                              			(opp.Migration_Old_Stage__c == 'Completing Meeting') 						||  
                              			(opp.Migration_Old_Stage__c == 'Implementing Partnership')
                                    )
                                
                                {
	                   				RequestedOppTask.Status = 'Completed';
 			                		BdTasksToUpdate.add(RequestedOppTask);
			                		system.debug('BdTasksToUpdate = ' + BdTasksToUpdate);
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
                     	
				   			when 'Partner Won', 'Partner Referring', 'Closed - Not Taken Up' {
				       			System.debug('Migration_Old_Stage__c Switch = ' + opp.Migration_Old_Stage__c);
                            	opp.StageName = 'Closed';
				   			}
                     	
				   		}
                       	BdOppsToUpdate.add(opp);

				   }
                    
				   when 'Professional Indemnity' {
				   		System.debug('ProductType Switch = ' + ProductType);

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
/*                                
                                If	(	(opp.Migration_Old_Stage__c == 'Booking Meeting') 							||
                              			(opp.Migration_Old_Stage__c == 'Completing Meeting') 						||  
                              			(opp.Migration_Old_Stage__c == 'Implementing Partnership')
                                    )
                                
                                {
	                   				RequestedOppTask.Status = 'Completed';
 			                		BdTasksToUpdate.add(RequestedOppTask);
			                		system.debug('BdTasksToUpdate = ' + BdTasksToUpdate);
                                }
*/
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
                    
				   when '(Insurance Audit' {
				       System.debug('ProductType Switch = ' + ProductType);
				   }
                    
				   when 'IR35 Insurance Audit' {
				       System.debug('ProductType Switch = ' + ProductType);
				   }
                    
				   when else {
				       System.debug('Switch - No match found');
				   }
				}                



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