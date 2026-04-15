public class PolicyEmailHandler implements Queueable {
    private String policyName;

    public PolicyEmailHandler(String policyName) {
        this.policyName = policyName;
    }

    public void execute(QueueableContext context) {
        // Calling your specific method
        //SendAutoDocsEmail.sendPurchaseEmail(this.policyName);
        // Bypass sendPurchaseEmail in test context
        if (!Test.isRunningTest()) {
            SendAutoDocsEmail.sendPurchaseEmail(policyName);
        }
    }
}