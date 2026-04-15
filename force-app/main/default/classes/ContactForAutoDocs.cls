public class ContactForAutoDocs {

    // Logic must be inside a method
    public void createOrFetchContact(String partnerId){ //String PartnerName) {
        
        // 1. Fetch the Partner Account
        Account partner = [SELECT Id, Name, Partner_ID__c, Cancellation_Notification_Email__c, Policy_Documents_Email__c 
                           FROM Account 
                           //WHERE Name = 'Test Partner 4000'
                           //Where Partner_ID__c = 'P-07175'
                           //WHERE Name =: PartnerName
                           Where RecordType.Name='Partner Accounts' And Partner_ID__c =: partnerId
                           LIMIT 1];

        String targetEmail = partner.Policy_Documents_Email__c;
        String cancelationEmail = partner.Cancellation_Notification_Email__c;
        Contact autoDocContact;
        Contact autoDocContactForCancelation;

        // 2. Check for an existing contact with the same Email and Account
        List<Contact> existingContacts = [SELECT Id FROM Contact 
                                          WHERE Email = :targetEmail 
                                          AND AccountId = :partner.Id 
                                          LIMIT 1];
        
        List<Contact> existingContactsForCancellation = [SELECT Id FROM Contact 
                                          WHERE Email = :cancelationEmail 
                                          AND AccountId = :partner.Id 
                                          LIMIT 1];

        if(!existingContacts.isEmpty()) {
            // 3. Use the existing contact
            autoDocContact = existingContacts[0];
        } else {
            // 4. Create a new one if no duplicate exists
            autoDocContact = new Contact(
                LastName = 'AutoDocsEmail',
                AccountId = partner.Id, 
                Email = targetEmail
            );
            insert autoDocContact;
        }
        if(!existingContactsForCancellation.isEmpty()) {
            // 3. Use the existing contact
            autoDocContactForCancelation = existingContactsForCancellation[0];
        } else {
            // 4. Create a new one if no duplicate exists
            autoDocContactForCancelation = new Contact(
                LastName = 'AutoDocsEmailForCancellation',
                AccountId = partner.Id, 
                Email = cancelationEmail
            );
            insert autoDocContactForCancelation;
        }
    }
}