@IsTest
public with sharing class OrganizationLimitsTest {

    @IsTest
    private static void orgLimitLog(){
        test.startTest();
        OrganizationLimits.scheduleMe();
        test.StopTest();
        Integer generatedLogQuantity = [SELECT Id FROM Limit_Log__c]?.size();
        Integer mapSize = OrgLimits.getMap().size();
        System.assertEquals(mapSize,generatedLogQuantity,'Org Limits Produced '+generatedLogQuantity+' Limit_Log__c records but there are ' + mapSize + ' in the map.');
    }

    @IsTest
    private static void removeOldLogs(){
        OrganizationLimits ol = new OrganizationLimits();
        
        List<Limit_Log__c> llList = new List<Limit_Log__c>();
        // If you change your retention period, make sure the CreatedDate value below is outside that period.
        // e.g., if your retention period is 1 year, set this to -2 years.
        llList.add(new Limit_Log__c(
            CreatedDate = DateTime.now().addYears(-10),
            Quota__c = 100,
            Limit__c = 'TestLimit',
            Actual__c = 50
        ));
        llList.add(new Limit_Log__c(
            CreatedDate = DateTime.now().addDays(-1),
            Quota__c = 100,
            Limit__c = 'TestLimit',
            Actual__c = 50
        ));
        insert llList;
        test.startTest();
        OrganizationLimits.scheduleMe();
        test.StopTest();
        // Expect the one from Yesterday is still there, but the one from ten years ago is not.
        System.assertEquals(1,[SELECT Id FROM Limit_Log__c WHERE Limit__c = 'TestLimit']?.size(),'generateLimitLog failed to remove logs past retention period.');
    }

    @IsTest
    private static void orgLimitLogError(){
        Boolean gotError = false;
        ol.TriggerErrorForTest = true;
        test.startTest();
        try {
            // Don't use scheduleMe() here because the flag was set on the instance of OrganizationLimits (not static)
            ol.generateLimitLog();
        } catch (Exception e){
            gotError = true;
        }
        test.StopTest();

        System.assertEquals(true,gotError,'Did not get an error as expected.');
    }

    @IsTest
    private static void generateCron(){
        DateTime now = DateTime.now();
        TimeZone tz = UserInfo.getTimeZone();
        // offset is given in microseconds, this converts to hours
        Integer offsetHour = 24 + (tz.getOffset(now)/60/60/1000) - 1;
        //0 59 '+offsetHour+' ? * MON-FRI *
        String cron = '0 59 '+offsetHour+' ? * MON-FRI *';
        test.startTest();
        System.assertEquals(cron,OrganizationLimits.getCronExpression(),'Cron expression was invalid');
        test.StopTest();
        
    }
}
