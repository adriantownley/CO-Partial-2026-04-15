@isTest
public class VexTestDataFactory
{

    
public static void createVexData(Integer numAccts, Integer numOppsPerAcct, Boolean policyRequired) 
{
    List<Account> 		CustomerAccts 	= new List<Account>();
    List<Opportunity> 	CustomerOpps 	= new List<Opportunity>();
    List<Product2> 		TestProducts 	= new List<Product2>();
    List<Policy__c> 	TestPolicies 	= new List<Policy__c>();
    List<String>		VexStatuses		= new List<String>();
    
   	//VexStatuses.add('VEX RIS Lower Approved');
    VexStatuses.add('VEX RAF Higher Approved');
   	VexStatuses.add('VEX RAF Lower Approved');
   	//VexStatuses.add('VEX RIS Higher Approved');
    

	Schema.DescribeFieldResult fieldResult = Opportunity.Win_Back_Opportunity__c.getDescribe();
	List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

	for (Schema.PicklistEntry entry : picklistValues) {
		System.debug(entry.getLabel() + ' : ' + entry.getValue());
	}
	Schema.PicklistEntry entry = picklistValues[0];
	System.debug('entry.getValue = ' + entry.getValue());
    
    Account 	test_partner;
    Account 	test_customer;
    Opportunity	test_opp;
    Product2 	test_product;
    Policy__c 	test_policy;
    DateTime 	policy_start = DateTime.now().addYears(-1).addDays(-1);
    
    
    for(Integer i=1;i<numAccts+1;i++) 
    {
        test_customer = new Account(
        FirstName = 'Vex Test',
        LastName = 'Customer ' + i,
        RecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND Name = 'Customer Accounts' LIMIT 1].Id,
        PersonEmail = 'testcustomer'+i+'@example.com',
        Phone = '07777666666',
        Business_Name__c = 'Test Inc' +i,
        OwnerId = UserInfo.getUserId()
        );
        CustomerAccts.add(test_customer);
    }
    insert CustomerAccts;
    
    for(Integer i=1;i<numAccts+1;i++) 
    {
        test_product = new Product2
            (
             Name = 'Test Vex PI Product '+i,
             ProductCode = 'PI',
             IsActive = true,
             Description = 'Vex Test PI Product',
             Purchase_With_Other__c = false,
             Default_Client_System__c = 'KCI'
        );
        TestProducts.add(test_product);
    }
    insert TestProducts;


    
    for(Integer i=1;i<numAccts+1;i++) 
    {
        for (Integer j=1;j<numOppsPerAcct+1;j++) 
        {
            test_opp = new Opportunity(
                Name = 'KCI: New Business - Vex TEST/'+i+'/'+j,
                RecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Opportunity' AND Name = 'New Business Opportunity' LIMIT 1].Id,
                CloseDate = Date.today().addYears(-1).addDays(-1),
                StageName = 'Prospecting',
                Type = 'New Business',
                Source_of_Leads__c = 'RAF',
                Win_Back_Opportunity__c = 'No',
                AccountId = CustomerAccts[i-1].Id,
        		Referred_By_Email__c = 'testreferred'+i+'@example.com',
                Referral_Friend_Name__c = 'Vex Test Refer '+i,
                Vex_Voucher_Status__c = VexStatuses[math.mod(i,VexStatuses.size())],
                OwnerId = UserInfo.getUserId()
            );
            CustomerOpps.add(test_opp);               
        }
    }
    insert CustomerOpps;
    
    
    for(Integer i=1;i<numAccts+1;i++) 
    {
        for (Integer j=1;j<numOppsPerAcct+1;j++) 
        {
        test_policy = new Policy__c(
                Name = 'Vex Test Policy/'+i+'/'+j,
                From_Opportunity__c = CustomerOpps[(i-1)+(j-1)].Id,
                Business_Type__c = 'NewBusiness',
                Issue_Date_Time__c = policy_start,
                Inception_Date_Time__c = policy_start,
                Expiry_Date_time__c = policy_start.addYears(1),
                OwnerId = UserInfo.getUserId(),
                Product__c = test_product.Id,
                Status__c = 'Live'
        );
    	If (PolicyRequired == True){
        	TestPolicies.add(test_policy);
    	}
        }
    }
    If (PolicyRequired == True){
        insert TestPolicies;
    }
    
}	// createVexData Method
}	// VexTestDataFactory Class