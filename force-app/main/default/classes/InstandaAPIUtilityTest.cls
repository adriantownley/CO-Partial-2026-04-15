@IsTest
public class InstandaAPIUtilityTest {

    
    public static testMethod void testCreateInstandaQuote() {
        String endpoint = 'https://example.com/api/quote';
        HttpRequest req = InstandaAPIUtility.createInstandaQuote(endpoint);

        // Verify the HttpRequest properties
        System.assertEquals('GET', req.getMethod());
        System.assertEquals(endpoint, req.getEndpoint());
        System.assertEquals('application/json', req.getHeader('Content-Type'));
        System.assertEquals('application/json', req.getHeader('Accept'));
    }

    public static testMethod void testInstandaQuoteConstructor_Rewardsme() {
        Lead lead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john@example.com',
            Phone = '1234567890',
            MobilePhone = '0987654321',
            Street = '123 Main St',
            City = 'Test City',
            PostalCode = '12345',
            Country = 'PH',
            Product_Type__c = 'Single Buying Journey',
            Company = 'Test Company'
        );
        insert lead;

        Test.startTest();
        InstandaAPIUtility.InstandaQuote quote = new InstandaAPIUtility.InstandaQuote(lead);
        Test.stopTest();

        System.assertEquals(lead.Id, quote.QuoteRef);
    }

    public static testMethod void testInstandaQuoteConstructor_FULLTrades() {
        Lead lead = new Lead(
            FirstName = 'Alice',
            LastName = 'Smith',
            Email = 'alice@example.com',
            Phone = '1111111111',
            MobilePhone = '2222222222',
            Street = '456 Another St',
            City = 'CityX',
            PostalCode = '54321',
            Country = 'PH',
            Product_Type__c = 'FUL Trades',
            Company = 'CompanyX'
        );
        insert lead;

        Test.startTest();
        InstandaAPIUtility.InstandaQuote quote = new InstandaAPIUtility.InstandaQuote(lead);
        Test.stopTest();

        System.assertEquals(lead.Id, quote.QuoteRef);
    }

    public static testMethod void testInstandaQuoteConstructor_AdmiralTrades() {
        Lead lead = new Lead(
            FirstName = 'Bob',
            LastName = 'Johnson',
            Phone = '3333333333',
            MobilePhone = '4444444444',
            Street = '789 Street',
            City = 'CityY',
            PostalCode = '67890',
            Country = 'PH',
            Product_Type__c = 'Admiral Trades',
            Company = 'CompanyY'
        );
        insert lead;

        Test.startTest();
        InstandaAPIUtility.InstandaQuote quote = new InstandaAPIUtility.InstandaQuote(lead);
        Test.stopTest();

        System.assertEquals(lead.Id, quote.QuoteRef);
    }
}