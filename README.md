# Salesforce Limit Log

## What the process does

This process will take a daily snapshot of your org limits. 

The code will schedule the process to run Monday-Friday at 23:59 GMT.  At that time, it will retrieve the `OrgLimits` system variable and create Limit Log records for each; about 52 per day.

It also deletes log records older than six months. 

## How to Set It Up

1. Create a custom object called Limit_Log__c, with three fields: Limit__c (String, 50); Actual__c (Integer); Quota__c (Integer).
2. Create a Permission Set that grants Modify All to the Limit Log object and grant it to the user who will be scheduling the process. I recommend using a system account rather than a named individual to ensure continuity in case of staff turnover.
3. Add the OrganizationLimits and OrganizationLimitsTest classes to your org.
4. Login as a user with the Permission Set and in Execute Anonymous, run:  ```OrganizationLimits.scheduleMe();```

## Notes

- The scheduleMe() process identifies your time zone and creates a cron expression for you. It automatically adjusts to ensure the snapshot will run at 23:59 GMT, just before limits roll over for the day.
- If you don't want to delete logs, remove the `delete` line at the end of the `generateLimitLog()` method, and remove the `removeOldLogs()` test method.
- If you want to change the retention period for logs, adjust the query at the end of `generateLimitLog()` beginning with `delete`. Then, in the `removeOldLogs()` test class, where it creates a test Limit Log with a createddate in the past using `addYears`, make sure the time span is larger than your new retention period.
