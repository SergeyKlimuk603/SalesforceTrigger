public with sharing class TestObjectParentTriggerHandler extends TriggerHandler {

    public TestObjectParentTriggerHandler() {
        System.debug('----TestObjectParentTriggerHandler runs' + '   ' + Trigger.operationType);

        OBJEC_TYPE = TestObjectParent__c.getSObjectType();
    }

    protected override void beforeUpdate() {
        System.debug('-----TRIGGER: ' + OBJEC_TYPE + '   ' + Trigger.operationType + ' START');

        switch on scenario {
            when SCENARIO_1 {
                beforeUpdate1();
            }
            when SCENARIO_2 {
                beforeUpdate2();
            }
        }

        System.debug('-----TRIGGER: ' + OBJEC_TYPE + '   ' + Trigger.operationType + ' FINISH');
    }

    protected override void afterUpdate() {
        System.debug('----TRIGGER: ' + OBJEC_TYPE + '   ' + Trigger.operationType + ' START');
        
        switch on scenario {
            when SCENARIO_1 {
                afterUpdate1();
            }
            when SCENARIO_2 {
                afterUpdate2();
            }
        }

        System.debug('-----TRIGGER: ' + OBJEC_TYPE + '   ' + Trigger.operationType + ' FINISH');
    }

    private void beforeUpdate1() {
        // После обновления TextField__c у дочернего объекта обновляется поле TextField__c у всех 
        // дочерних объектов того же родителя.
    }

    private void afterUpdate1() {
        // После обновления TextField__c у дочернего объекта обновляется поле TextField__c у всех 
        // дочерних объектов того же родителя.
    }

    private void beforeUpdate2() {
        // После обновления TextField__c у дочернего объекта обновляется TextField__c у родителя и
        // затем у всех его дочерних объектов.
        List<TestObjectParent__c> testObjectParentsNew = Trigger.new;

        for (TestObjectParent__c testObjectParent : testObjectParentsNew) {
            testObjectParent.NumberField__c = testObjectParent.TextField__c.length();
        }
    }

    private void afterUpdate2() {
        // После обновления TextField__c у дочернего объекта обновляется TextField__c у родителя и
        // затем у всех его дочерних объектов.
        List<TestObjectParent__c> testObjectParentsNew = Trigger.new;
     
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