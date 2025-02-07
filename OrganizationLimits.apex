global with sharing class OrganizationLimits implements Schedulable{
    
    global OrganizationLimits(){}
    public Boolean TriggerErrorForTest = false;

    public static String getCronExpression(){
        // This will read the user's time zone and generate a cron so it runs at 23:59 GMT Monday-Friday
        DateTime now = DateTime.now();
        TimeZone tz = UserInfo.getTimeZone();
        // offset is given in microseconds, this converts to hours
        Integer offsetHour = 24 + (tz.getOffset(now)/60/60/1000) - 1;
        //0 59 '+offsetHour+' ? * MON-FRI *
        String cron = '0 59 '+offsetHour+' ? * MON-FRI *';
        return cron;
    }

    global void generateLimitLog(){
        try {
            Map<String,System.OrgLimit> limitsMap = OrgLimits.getMap();
            List<Limit_Log__c> toInsert = new List<Limit_Log__c>();
            for (System.OrgLimit lim : limitsMap.values()){
                toInsert.add(new Limit_Log__c (
                    Limit__c = lim.getName(),
                    Actual__c = lim.getValue(),
                    Quota__c = lim.getLimit())) ;
            }
            insert toInsert;
            if (TriggerErrorForTest){
                throw new TMException('TEST_ERROR');
            }
            // Adjust your retention period here
            delete [SELECT Id FROM Limit_Log__c WHERE CreatedDate < LAST_N_MONTHS:6];
        }
        catch (Exception e){
            // Add your error handling here
            throw e;
        }
       
    }
    global static String scheduleMe(){
        OrganizationLimits ol = new OrganizationLimits();
        if (!Schema.sObjectType.Contact.isDeletable() || !Schema.sObjectType.Contact.isCreateable()){
            throw new TMException('Running user must have permission to Create and Delete Limit_Log__c records. Add the Limit Log Permission Set.');
        }
        return System.schedule('OrganizationLimits', getCronExpression(), ol);
    }
    global void execute(SchedulableContext SC) 
    {
        OrganizationLimits ol = new OrganizationLimits(); 
        ol.generateLimitLog();
    }

    public Class MyException extends Exception{}
}
