global class EmailToLeadProcessor implements Messaging.InboundEmailHandler {
    public Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, 
                                                       Messaging.InboundEnvelope env){
 
    // Create an InboundEmailResult object for returning the result of the 
    // Apex Email Service
    Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
    Id recordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Lead' and Name ='Customer Lead' Limit 1].Id;
                                                           
    ///Create a lead
    Lead l = new Lead();
        //l.email='anothertestC@gmail.com';
        l.Status='New';
        l.lastname='Refer@kingsbridge lead';                                                  
        l.RecordTypeId = recordTypeId;  
        l.Source__c='Direct';
        l.Description = 'Content of the email:\n' + email.plainTextBody;
        //l.Description = email.fromAddress.substringAfter('@'); 
        l.Referred_By_Email__c =email.fromAddress;                                                  
        try {
            insert l;
            System.debug('Lead inserted with ID: ' + l.Id);
        } catch (Exception e) {
            System.debug('DML Exception: ' + e.getMessage());
        }                                                                                                       
  result.success = true;
  return result;
      }
}