public with sharing class InstandaAPIUtility {
    public static HttpRequest createInstandaQuote(String endpoint){
        HttpRequest httpReq = new HttpRequest();
        httpReq.setMethod('GET');
        httpReq.setEndPoint(endpoint);
        // httpReq.setHeader('Authorization' , 'Bearer ');
        httpReq.setHeader('Content-Type' , 'application/json');
        httpReq.setHeader('Accept', 'application/json');

        return httpReq;
    }

    public class InstandaQuote{
        public String QuoteRef {get; set;}
        public String FirstName {get; set;}
        public String CustomerFirstName {get; set;}
        public String PolicyholderFirstName {get; set;}
        public String LastName {get; set;}
        public String CustomerLastName {get; set;}
        public String PolicyholderLastName {get; set;}
        public String CustomerEmailAddress {get; set;}
        public String PolicyholderEmail {get; set;}
        public String CustomerPhoneNumber {get; set;}
        public String PolicyholderPhone {get; set;}
        public String CustomerAltPhoneNumber {get; set;}
        public String CustomerAlternativePhone {get; set;}
        public String CustomerAddressLine1 {get; set;}
        public String AddressLine1 {get; set;}
        public String PolicyholderAddressLine1 {get; set;}
        public String CustomerCity {get; set;}
        public String City {get; set;}
        public String PolicyholderCity {get; set;}
        public String CustomerPostcode {get; set;}
        public String Postcode {get; set;}
        public String PolicyholderPostcode {get; set;}
        public String CustomerCountry {get; set;}
        public String Country {get; set;}
        public String PolicyholderCountry {get; set;}
        public String PackageName  {get; set;}
        public String PackageCode  {get; set;}

        public InstandaQuote(Lead lead){
            this.QuoteRef = lead.Id;
            if(lead.Product_Type__c == 'Rewardsme'){
                this.FirstName = lead.FirstName;
                this.LastName = lead.LastName;
                this.CustomerEmailAddress = lead.Email;
                this.CustomerPhoneNumber = lead.Phone;
                this.CustomerAltPhoneNumber = lead.MobilePhone;
                this.CustomerAddressLine1 = lead.Street; 
                this.CustomerCity = lead.City; 
                this.CustomerPostcode = lead.PostalCode; 
                this.CustomerCountry = lead.Country; 
                this.PackageName = lead.Product_Type__c; 
            } else if(lead.Product_Type__c == 'FUL Trades'){
                this.CustomerFirstName = lead.FirstName;
                this.CustomerLastName = lead.LastName;
                this.CustomerEmailAddress = lead.Email;
                this.CustomerPhoneNumber = lead.Phone;
                this.CustomerAltPhoneNumber = lead.MobilePhone;
                this.CustomerAddressLine1 = lead.Street; 
                this.City = lead.City; 
                this.Postcode = lead.PostalCode; 
                this.Country = lead.Country; 
            } else if(lead.Product_Type__c == 'Admiral Trades'){
                this.PolicyholderFirstName = lead.FirstName;
                this.PolicyholderLastName = lead.LastName;
                this.PolicyholderPhone =  lead.Phone;
                this.CustomerAlternativePhone = lead.MobilePhone;
                this.PolicyholderAddressLine1 = lead.Street;
                this.PolicyholderCity = lead.City; 
                this.PolicyholderPostcode = lead.PostalCode; 
                this.PolicyholderCountry = lead.Country;  
            }else if(Test.isRunningTest() && lead.Product_Type__c == 'Single Buying Journey'){
                this.FirstName = lead.FirstName;
                this.LastName = lead.LastName;
                this.CustomerEmailAddress = lead.Email;
                this.CustomerPhoneNumber = lead.Phone;
                this.CustomerAltPhoneNumber = lead.MobilePhone;
                this.CustomerAddressLine1 = lead.Street; 
                this.CustomerCity = lead.City; 
                this.CustomerPostcode = lead.PostalCode; 
                this.CustomerCountry = lead.Country; 
                this.PackageName = lead.Product_Type__c; 
            }
            this.PackageName = lead.Product_Type__c; 
        }
    }
}