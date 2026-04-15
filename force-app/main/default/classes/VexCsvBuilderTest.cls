@isTest


private class VexCsvBuilderTest {

    
    @isTest static void testRafHigher() 
    {
        list<VexCsvBuilder.MyOutputs> 	OutputParams = new list<VexCsvBuilder.MyOutputs>();
        list<VexCsvBuilder.MyInputs> 	InputParams  = new list<VexCsvBuilder.MyInputs>();
        
        VexTestDataFactory.createVexData(4,1,True);
        
        VexCsvBuilder.MyInputs MyIP = new VexCsvBuilder.MyInputs();
        VexCsvBuilder.MyOutputs MyOP = new VexCsvBuilder.MyOutputs();
        
        MyIP.VexVoucherTypeIP = 'RAF';
        MyIP.VexVoucherLevelIP = 'Higher';
        MyIP.VexIncludeHeaderIP = True;
        MyIP.VexSaveFile = True;
        MyIP.VexSendEmail = True;        
        InputParams.add(MyIP);
        
        MyOP.VexSuccessfulOP = False;
        MyOP.VexReturnMsgOP = 'Test Started';
        OutputParams.add(MyOP);
       
        OutputParams = VexCsvBuilder.RunVex(InputParams);
        
        System.assertEquals('RAF Higher Report Completed Successfully!',OutputParams[0].VexReturnMsgOP,'Expected RAF Higher Report Completed Successfully!');
    }
    

    @isTest static void testRafLower() 
    {
        
        list<VexCsvBuilder.MyOutputs> 	OutputParams = new list<VexCsvBuilder.MyOutputs>();
        list<VexCsvBuilder.MyInputs> 	InputParams  = new list<VexCsvBuilder.MyInputs>();
        
        VexTestDataFactory.createVexData(4,1,True);

        VexCsvBuilder.MyInputs MyIP = new VexCsvBuilder.MyInputs();
        VexCsvBuilder.MyOutputs MyOP = new VexCsvBuilder.MyOutputs();
        
        MyIP.VexVoucherTypeIP = 'RAF';
        MyIP.VexVoucherLevelIP = 'Lower';
        MyIP.VexIncludeHeaderIP = True;
        MyIP.VexSaveFile = True;
        MyIP.VexSendEmail = True;
        InputParams.add(MyIP);
        
        MyOP.VexSuccessfulOP = False;
        MyOP.VexReturnMsgOP = 'Test Started';
        OutputParams.add(MyOP);

        OutputParams = VexCsvBuilder.RunVex(InputParams);
        
        System.assertEquals('RAF Lower Report Completed Successfully!',OutputParams[0].VexReturnMsgOP,'Expected RAF Lower Report Completed Successfully!');
    }
    
    
    @isTest static void testNoVouchers() 
    {
        VexCsvBuilder.MyOutputs test = new VexCsvBuilder.MyOutputs();
        list<VexCsvBuilder.MyOutputs> 	OutputParams = new list<VexCsvBuilder.MyOutputs>();
        list<VexCsvBuilder.MyInputs> 	InputParams  = new list<VexCsvBuilder.MyInputs>();
        
        VexTestDataFactory.createVexData(4,1,True);

        VexCsvBuilder.MyInputs MyIP = new VexCsvBuilder.MyInputs();
        VexCsvBuilder.MyOutputs MyOP = new VexCsvBuilder.MyOutputs();
        
        MyIP.VexVoucherTypeIP = 'RAF';
        MyIP.VexVoucherLevelIP = 'Lower';
        MyIP.VexIncludeHeaderIP = True;
        MyIP.VexSaveFile = True;
        MyIP.VexSendEmail = True;
        InputParams.add(MyIP);
        
        MyOP.VexSuccessfulOP = False;
        MyOP.VexReturnMsgOP = 'Test Started';
        OutputParams.add(MyOP);

        OutputParams = VexCsvBuilder.RunVex(InputParams);
        OutputParams = VexCsvBuilder.RunVex(InputParams);
        System.assertEquals('RAF Lower Report Failed! No Vouchers To Extract!',OutputParams[0].VexReturnMsgOP,'Expected RAF Lower Report Completed Successfully!');
    }
    

    @isTest static void testNoPolicy() 
    {
        VexCsvBuilder.MyOutputs test = new VexCsvBuilder.MyOutputs();
        list<VexCsvBuilder.MyOutputs> 	OutputParams = new list<VexCsvBuilder.MyOutputs>();
        list<VexCsvBuilder.MyInputs> 	InputParams  = new list<VexCsvBuilder.MyInputs>();
        
        VexTestDataFactory.createVexData(4,1,False);

        VexCsvBuilder.MyInputs MyIP = new VexCsvBuilder.MyInputs();
        VexCsvBuilder.MyOutputs MyOP = new VexCsvBuilder.MyOutputs();
        
        MyIP.VexVoucherTypeIP = 'RAF';
        MyIP.VexVoucherLevelIP = 'Higher';
        MyIP.VexIncludeHeaderIP = True;
        MyIP.VexSaveFile = True;
        MyIP.VexSendEmail = True;
        InputParams.add(MyIP);
        
        MyOP.VexSuccessfulOP = False;
        MyOP.VexReturnMsgOP = 'Test Started';
        OutputParams.add(MyOP);

        OutputParams = VexCsvBuilder.RunVex(InputParams);
        System.assertEquals('RAF Higher Report Completed Successfully!',OutputParams[0].VexReturnMsgOP,'Expected RAF Higher Report Completed Successfully!');
    }
    

    @isTest static void testNoParameters() 
    {
        VexCsvBuilder.MyOutputs test = new VexCsvBuilder.MyOutputs();
        list<VexCsvBuilder.MyOutputs> 	OutputParams = new list<VexCsvBuilder.MyOutputs>();
        list<VexCsvBuilder.MyInputs> 	InputParams  = new list<VexCsvBuilder.MyInputs>();
        
        VexCsvBuilder.MyInputs MyIP = new VexCsvBuilder.MyInputs();
        VexCsvBuilder.MyOutputs MyOP = new VexCsvBuilder.MyOutputs();

        MyOP.VexSuccessfulOP = False;
        MyOP.VexReturnMsgOP = 'Test Started';
        OutputParams.add(MyOP);
        
        OutputParams = VexCsvBuilder.RunVex(InputParams);
    }
    
}