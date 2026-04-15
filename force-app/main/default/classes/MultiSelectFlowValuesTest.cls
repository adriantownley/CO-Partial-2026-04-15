@IsTest
public class MultiSelectFlowValuesTest {

    @IsTest
    static void testCheckValues_withValues() {
        // Arrange
        List<String> inputValues = new List<String>{
            'Apple;Banana;Orange'
        };

        // Act
        Test.startTest();
        List<List<String>> result = MultiSelectFlowValues.CheckValues(inputValues);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Outer list should have one entry');
        System.assertEquals(3, result[0].size(), 'Inner list should contain 3 values');
        System.assertEquals('Apple', result[0][0]);
        System.assertEquals('Banana', result[0][1]);
        System.assertEquals('Orange', result[0][2]);
    }

    @IsTest
    static void testCheckValues_emptyList() {
        // Arrange
        List<String> inputValues = new List<String>();

        // Act
        Test.startTest();
        List<List<String>> result = MultiSelectFlowValues.CheckValues(inputValues);
        Test.stopTest();

        // Assert
        System.assertEquals(null, result, 'Result should be null when input list is empty');
    }
}