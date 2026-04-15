global class DelayedEmailJob implements Schedulable {
    global String policyName;

    // Constructor to pass the policy name
    public DelayedEmailJob(String name) {
        this.policyName = name;
    }

    global void execute(SchedulableContext sc) {
        SendEmailFromSF.sendEmailAsync(policyName);
    }
}