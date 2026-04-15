trigger AutoDocsDocumentsRecieved on Policy__c (after update){//(before insert) {
    /*
    //helper method to build cron expression
    public static String buildCronExpression(Datetime dt) {
        return String.format('{0} {1} {2} {3} {4} ? {5}',
                             new String[] {
                                 String.valueOf(dt.second()),
                                 String.valueOf(dt.minute()),
                                 String.valueOf(dt.hour()),
                                 String.valueOf(dt.day()),
                                 String.valueOf(dt.month()),
                                 String.valueOf(dt.year())
                                     }
                            );
    }
    
    // actual trigger logic
    for (Policy__c policy : Trigger.new) {
        Policy__c oldPolicy = Trigger.oldMap.get(policy.Id);

        // Check if the field changed to true
        /*old working
        if (policy.Documents_for_partners_received__c == true &&
            oldPolicy.Documents_for_partners_received__c != true) {

            // Call the method with the policy name
            //SendEmailFromSF.sendEmail(policy.Name);
            SendEmailFromSF.sendEmailAsync(policy.Name);

        }old working ends*/
        /*if (policy.Documents_for_partners_received__c == true &&
            oldPolicy.Documents_for_partners_received__c != true) {

            // Calculate time 2 minutes from now
            Datetime runTime = System.now().addMinutes(2);

            // Build cron expression for 2 minutes later
            String cronExp = buildCronExpression(runTime);

            // Schedule the job with a unique name
            String jobName = 'DelayedEmail_' + policy.Id;
            System.schedule(jobName, cronExp, new DelayedEmailJob(policy.Name));
        }
    }
    //if (Trigger.isAfter && Trigger.isUpdate) {
    //    PolicyTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    //}
    */   
    // Helper method moved to a logic class is best practice, 
    // but kept here for the fix.
   /* public static String buildCronExpression(Datetime dt) {
        return String.format('{0} {1} {2} {3} {4} ? {5}',
            new String[] {
                String.valueOf(dt.second()),
                String.valueOf(dt.minute()),
                String.valueOf(dt.hour()),
                String.valueOf(dt.day()),
                String.valueOf(dt.month()),
                String.valueOf(dt.year())
            }
        );
    }
    
    // actual trigger logic
    for (Policy__c policy : Trigger.new) {
        // Safe to access oldMap in 'after update'
        Policy__c oldPolicy = Trigger.oldMap.get(policy.Id);

        // Check if the field changed from false/null to true
        if (policy.Documents_for_partners_received__c == true && 
            (oldPolicy == null || oldPolicy.Documents_for_partners_received__c != true)) {

            // Calculate time 2 minutes from now
            Datetime runTime = System.now().addMinutes(2);

            // Build cron expression
            String cronExp = buildCronExpression(runTime);

            // Schedule the job with the now-existing record ID
            String jobName = 'DelayedEmail_' + policy.Id + '_' + System.now().getTime();
            
            // Check to ensure we don't exceed scheduling limits or duplicate names
            System.schedule(jobName, cronExp, new DelayedEmailJob(policy.Name));
        }
    }*/
    for (Policy__c pol : Trigger.new) {
        Policy__c oldPol = Trigger.oldMap.get(pol.Id);

        // Check if the field was changed to true
        if (pol.Documents_for_partners_received__c == true && 
            oldPol.Documents_for_partners_received__c == false) {
            
            // Enqueue the job with a 2-minute delay (120 seconds)
            System.enqueueJob(new PolicyEmailHandler(pol.Name), 2);
        }
    }

}