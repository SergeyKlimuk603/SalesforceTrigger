public with sharing class TestObjectParentTriggerHandler extends TriggerHandler {

    public static TestScenario scenario;

    public TestObjectParentTriggerHandler() {
        System.debug('----TestObjectParentTriggerHandler runs' + '   ' + Trigger.operationType);

        OBJEC_TYPE = TestObjectParent__c.getSObjectType();
    }

    protected override void beforeUpdate(List<SObject> newChangedRecords, Map<Id, SObject> oldChangedRecordsMap) {
        System.debug('-----TRIGGER: ' + OBJEC_TYPE + '   ' + Trigger.operationType + ' START');

        List<TestObjectParent__c> testObjectParentsNew = newChangedRecords;
        Map<Id, TestObjectParent__c> testObjectParentsOldMap = 
            new Map<Id, TestObjectParent__c>((List<TestObjectParent__c>) oldChangedRecordsMap.values());

        switch on scenario {
            when SCENARIO_1 {
                beforeUpdate1(testObjectParentsNew, testObjectParentsOldMap);
            }
            when SCENARIO_2 {
                beforeUpdate2(testObjectParentsNew, testObjectParentsOldMap);
            }
        }

        System.debug('-----TRIGGER: ' + OBJEC_TYPE + '   ' + Trigger.operationType + ' FINISH');

    }

    protected override void afterUpdate(List<SObject> newChangedRecords, Map<Id, SObject> oldChangedRecordsMap) {
        System.debug('----TRIGGER: ' + OBJEC_TYPE + '   ' + Trigger.operationType + ' START');
        
        List<TestObjectParent__c> testObjectParentsNew = newChangedRecords;
        Map<Id, TestObjectParent__c> testObjectParentsOldMap = 
            new Map<Id, TestObjectParent__c>((List<TestObjectParent__c>) oldChangedRecordsMap.values());

        switch on scenario {
            when SCENARIO_1 {
                afterUpdate1(testObjectParentsNew, testObjectParentsOldMap);
            }
            when SCENARIO_2 {
                afterUpdate2(testObjectParentsNew, testObjectParentsOldMap);
            }
        }

        System.debug('-----TRIGGER: ' + OBJEC_TYPE + '   ' + Trigger.operationType + ' FINISH');
    }

    private void beforeUpdate1(List<TestObjectParent__c> testObjectParentsNew, Map<Id, TestObjectParent__c> testObjectParentsOldMap) {
        // После обновления TextField__c у дочернего объекта обновляется поле TextField__c у всех 
        // дочерних объектов того же родителя.
    }

    private void afterUpdate1(List<TestObjectParent__c> testObjectParentsNew, Map<Id, TestObjectParent__c> testObjectParentsOldMap) {
        // После обновления TextField__c у дочернего объекта обновляется поле TextField__c у всех 
        // дочерних объектов того же родителя.
    }

    private void beforeUpdate2(List<TestObjectParent__c> testObjectParentsNew, Map<Id, TestObjectParent__c> testObjectParentsOldMap) {
        // После обновления TextField__c у дочернего объекта обновляется TextField__c у родителя и
        // затем у всех его дочерних объектов.

        for (TestObjectParent__c testObjectParent : testObjectParentsNew) {
            testObjectParent.NumberField__c = testObjectParent.TextField__c.length();
        }
    }

    private void afterUpdate2(List<TestObjectParent__c> testObjectParentsNew, Map<Id, TestObjectParent__c> testObjectParentsOldMap) {
        // После обновления TextField__c у дочернего объекта обновляется TextField__c у родителя и
        // затем у всех его дочерних объектов.
     
        List<TestObjectParent__c> parentsById = new List<TestObjectParent__c>([
            SELECT Id, TextField__c, NumberField__c, (SELECT Id, TextField__c, NumberField__c FROM TestObjects__r)
            FROM TestObjectParent__c
            WHERE Id IN :testObjectParentsNew
        ]);


        List<TestObject__c> testObjectForUpdate = new List<TestObject__c>();
        for (TestObjectParent__c testObjectParent : parentsById) {
            for (TestObject__c testObject : testObjectParent.TestObjects__r) {
                testObject.TextField__c = testObjectParent.TextField__c;
                testObjectForUpdate.add(testObject);
            }
        }

        update testObjectForUpdate;
    }
}