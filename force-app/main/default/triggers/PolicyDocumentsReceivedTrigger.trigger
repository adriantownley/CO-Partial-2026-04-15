trigger PolicyDocumentsReceivedTrigger on Policy__c (after update) {
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
        if (policy.Documents_for_partners_received__c == true &&
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
}