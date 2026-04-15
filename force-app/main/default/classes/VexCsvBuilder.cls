public without sharing class VexCsvBuilder {

   
    public class MyInputs {
        
    @AuraEnabled @InvocableVariable
    public String 	VexVoucherTypeIP;
    
    @AuraEnabled @InvocableVariable
    public String 	VexVoucherLevelIP;

    @AuraEnabled @InvocableVariable
    public Boolean	VexIncludeHeaderIP;
        
    @AuraEnabled @InvocableVariable
    public Boolean 	VexSaveFile;
        
    @AuraEnabled @InvocableVariable
    public Boolean 	VexSendEmail;
}

    public class MyOutputs {
        
    @AuraEnabled @InvocableVariable 
    public Boolean VexSuccessfulOP;
        
    @AuraEnabled @InvocableVariable 
    public String	VexReturnMsgOP;
      
}
	

    
   	public static string finalstr{get;set;}
   	public static string globalReturnMessage = 'Initialised';
    public static boolean globalSuccessStatus = False;
	public static list<MyOutputs> OutputParams = new list<MyOutputs>();
	public static MyOutputs thisline = new MyOutputs();   
    public static ContentWorkspace 	ws = new ContentWorkspace (); //KOS-27289 - Moved variable to public area
	public static Vex_Voucher_Value__mdt voucherValues = new Vex_Voucher_Value__mdt();
	
	@InvocableMethod(label='Run Vex Reports' description='Runs Selected Vex Reports.' category='Vex Reports')
    public static List<MyOutputs> RunVex(List<MyInputs> InputParams)
    {
    	If  (!(InputParams.isEmpty())) {
            
            //KOS-27289 - Start
        	try{
				ws = [SELECT Id, RootContentFolderId FROM ContentWorkspace WHERE Name = 'VEX Vouchers' LIMIT 1];
        	} 	catch(Exception e) {
    			System.debug('The following exception has occurred: ' + e.getMessage());
                globalSuccessStatus = False;
	    		globalReturnMessage = ('Cannot Access Library - check User has Salesforce CRM Content User permission and the VEX Vouchers Library is shared with them!');
    			thisline.VexSuccessfulOP 	= globalSuccessStatus;
    			thisline.VexReturnMsgOP 	= globalReturnMessage;
   				OutputParams.add(thisline);
            	return OutputParams;
			}
            //KOS-27289 - End

			// Get the Voucher Values.
			voucherValues = [SELECT Id, Vex_Higher_Voucher_Value__c, Vex_Lower_Voucher_Value__c FROM Vex_Voucher_Value__mdt];
           
       		BuildVexCsv(InputParams[0].VexVoucherTypeIP,
                        InputParams[0].VexVoucherLevelIP,
                        InputParams[0].VexIncludeHeaderIP,
                        InputParams[0].VexSaveFile,
                        InputParams[0].VexSendEmail
                        );

    }
	else
    {
 		system.debug('InputParams EMPTY');
   	    globalSuccessStatus = False;
	    globalReturnMessage = ('Report Failed! InputParams EMPTY!');
   	}
    thisline.VexSuccessfulOP 	= globalSuccessStatus;
    thisline.VexReturnMsgOP 	= globalReturnMessage;
    OutputParams.add(thisline);
    return OutputParams;
    }
    
    
    
    
    public static void createFile (String filename, String content, String folder)
    {
        ContentVersion 		cv = new ContentVersion();
//      ContentWorkspace 	ws = new ContentWorkspace (); KOS-27289 - variable moved to public area
        
		cv.VersionData 	= Blob.valueOf(content);
		cv.Title 		= filename;
		cv.PathOnClient = filename;
		insert cv;

		cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
//		ws = [SELECT Id, RootContentFolderId FROM ContentWorkspace WHERE Name = :folder LIMIT 1]; KOS-27289 Moved to Library Error Check
        
		ContentDocumentLink cdl = new ContentDocumentLink();
		cdl.ContentDocumentId = cv.ContentDocumentId;
		cdl.ShareType = 'I';
		cdl.Visibility = 'AllUsers';
		cdl.LinkedEntityId = ws.Id; //Magic happens here
        insert cdl;
	}
    
	public static void createEmail (String filename, String content, String Insubject)
    {  // Possible future enhancement- Commented out for now! 
        
//        Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
//		blob csvBlob = Blob.valueOf(content);
//        string csvname= filename;
//        csvAttc.setFileName(csvname);
//        csvAttc.setBody(csvBlob);
//        Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
//        String[] toAddresses = new list<string> {'adrian.townley@kingsbridge.co.uk'};
//        String subject =InSubject;
//                    system.debug(csvAttc);        
// 
//        email.setSubject(subject);
//		email.setToAddresses( toAddresses );
//		email.setPlainTextBody('Account CSV ');
//		email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
//		Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
    }

    
     
  	public static void BuildVexCsv(String VoucherType, String VoucherLevel, Boolean includeHeader, Boolean saveCsvFile, Boolean sendCsvEmail)
    {
        String filterString;
        String voucherStatus;
        String newVoucherStatus;
       	String vexReason;
       	String vexNotes;
        string vexAmount;
        string vexPolicy;
        
        // String Constants for all vouchers.
        String vexBrand 	= 'VEX Multi-Choice';
        String vexSubject 	= 'Here\'s your Voucher from Kingsbridge';
      	String vexMessage 	= 'We hope you enjoy spending your attached e-gift';
      	String vexProgramId = 'KIN1011';
        // End String Constants for all vouchers.
        
        // Set time stamp for following day at 20:00GMT/19:00BST.
        Date myDate = Date.Today();
		Time myTime = Time.newInstance(18, 45, 0, 0);
		DateTime vexSendDate = DateTime.newInstance(myDate, myTime);
        // Format for Time Zone and adjust for daylight saving time.
        String VexConvertedDate = vexSendDate.format('dd/MM/yyyy HH:mm', 'Europe/London');
        // End Set time stamp.

             
        
        if ((VoucherType == 'RAF') && (VoucherLevel == 'Higher'))
        {
                 	vexReason 		= VoucherType;  
        }
        else
        {
                 	vexReason 		= VoucherType + ' ' + VoucherLevel;
        }
        
        
        filterString		= '%' + VoucherType + '%';
        voucherStatus		= 'VEX ' + VoucherType + ' ' + VoucherLevel + ' Approved';
        newVoucherStatus	= 'VEX ' + VoucherType + ' Sent';
       	vexNotes 			= 'VEX ' + VoucherType + ' ' + VoucherLevel;   
        
        List<Opportunity> oppsList = [SELECT 	Name, 											/*Opp Name*/
                                      			Referral_Friend_Name__c, 						/*Name of referring person*/
                                      			Referred_By_Email__c, 							/*Email of referring person*/
                               					(SELECT Name FROM Policies__r LIMIT 1),			/*Related Policy*/
                                      			Vex_Voucher_Status__c							/*Opp Voucher Status*/
                                      FROM Opportunity 
                                      WHERE 
                                   		(Vex_Voucher_Status__c = :voucherStatus)
                                 		AND 
                                     	(Source_of_Leads__c = 'RAF')
									 ];
        
		system.debug('OppsList = ' + OppsList);
        
        If (Oppslist.size() > 0){
            
        	// Add a header to the Csv file if selected as an option.
        	If (IncludeHeader == TRUE) 
        	{
        		string header 		= 'Col A,Recipient Name,Recipient Email,Col D,Value,Brand,Subject,Reason,Message,Send Date and Time,Col K,Col L,Policy Number,Notes,Amazon Program ID \n';
				finalstr = header ;            
        	}
        
        	// Loop through our list of returned Opps.
        	for (Opportunity opp : OppsList)
        	{

        		if (VoucherLevel == 'Higher')  
        		{
                 	vexAmount 		= voucherValues.Vex_Higher_Voucher_Value__c;  
        		}
     	   		else
        		{
        	         vexAmount 		= voucherValues.Vex_Lower_Voucher_Value__c;
    	    	}
            
//	         	Check here for empty Policy List
            	If (opp.Policies__r.size() > 0) {
            		vexPolicy = opp.Policies__r[0].name;
            	}else{
                	vexPolicy = 'NO POLICY FOUND!';
            	}
            
            
            	string recordString = 	','													+
                						opp.Referral_Friend_Name__c							+','+
                						opp.Referred_By_Email__c							+','+                
										','													+
                						vexAmount											+','+ 
                						vexBrand											+','+ 
    	            					vexSubject											+','+ 
        	        					vexReason											+','+ 
            	    					vexMessage											+','+ 
										VexConvertedDate									+','+												+
										','													+
										','													+
                						vexPolicy											+','+
                						vexNotes											+','+ 
        	        					vexProgramID										+
                						'\n';
            
				// Append this row to the csv file.
                if (finalstr == null) {
            	finalstr = recordString;
                } else{
            	finalstr = finalstr +recordString;
                }
            
            	// Modify the Status to Sent and the sent date to Today.
            	opp.Vex_Voucher_Status__c 	= newVoucherStatus;
            	opp.Voucher_sent_date__c 	= Date.Today();
            
            
        
        	}
        
        	try{
        
        		// Save the Updated Opportunity List.
        		Update OppsList;
        
        		system.debug('finalstr = ' + finalstr);
        		DateTime dt = DateTime.now();
        		String dateTimeStr = dt.format('yyyy/MM/dd hh:mm:ss');
				String inString = VoucherType + '-' + VoucherLevel + '-' + dateTimeStr+'.csv';

        		If (saveCsvFile == TRUE)
        		{
            		createFile (InString, finalStr, 'VEX Vouchers');
        		}
        		If (sendCsvEmail == TRUE)
        		{
            		createEmail (InString, finalStr, 'VEX Vouchers');
        		}
            	globalSuccessStatus = True;
            	globalReturnMessage = (VoucherType + ' ' + VoucherLevel + ' Report Completed Successfully!');
        
            
        	} 
        		catch(DmlException e) {
        		system.debug('Error - ' + e);            
    	        globalSuccessStatus = False;
	            globalReturnMessage = (VoucherType + ' ' + VoucherLevel + ' Report Failed! Error Returned = ' + e.getMessage());

        	}
            
            
            
            
        }
        Else{
    		globalSuccessStatus = False;
	      	globalReturnMessage = (VoucherType + ' ' + VoucherLevel + ' Report Failed! No Vouchers To Extract!');
        }
        
        

    }

        
}