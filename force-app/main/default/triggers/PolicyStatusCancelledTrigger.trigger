trigger PolicyStatusCancelledTrigger on Policy__c (after update) {
    List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();

    // Fetch the template ID once
    Id templateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Partner_Policy_Cancelation_VF' LIMIT 1].Id;
    // Create a dummy contact to use as recipient (since targetObjectId is required)
    Contact dummyRecipient = [SELECT Id from Contact where email='lukasz.zawieja@gmail.com'];

    for (Policy__c policy : Trigger.new) {
        Policy__c oldPolicy = Trigger.oldMap.get(policy.Id);

        if (policy.Status__c == 'Cancelled' && oldPolicy.Status__c != 'Cancelled') {
            if (String.isNotBlank(policy.Partner_Cancellation_Notification_Email__c)) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] { policy.Partner_Cancellation_Notification_Email__c });
                mail.setTemplateId(templateId);
                mail.setWhatId(policy.Id); // Links email to the Policy__c record
                mail.setSaveAsActivity(false); // Optional: prevent logging in Activity History
                mail.setTargetObjectId(dummyRecipient.Id); // recipient

                emailList.add(mail);
            }
        }
    }

    if (!emailList.isEmpty()) {
        Messaging.sendEmail(emailList);
    }
}