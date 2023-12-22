public with sharing class TestObjectTriggerHandler extends TriggerHandler {

    public static String textFieldValueForTests;
    List<TestObject__c> testObjectsNew;

    public TestObjectTriggerHandler() {
        OBJEC_TYPE = TestObject__c.getSObjectType();
        testObjectsNew = Trigger.new;
    }

    protected override void beforeUpdate() {
        System.debug('----- ' + getTriggerDepthLogPrefix() + ' TRIGGER: ' + OBJEC_TYPE + '   ' + Trigger.operationType + ' START');

        switch on scenario {
            when SCENARIO_0 {
                beforeUpdate0();
            }
            when SCENARIO_1 {
                beforeUpdate1();
            }
            when SCENARIO_2 {
                beforeUpdate2();
            }
        }

        System.debug('----- ' + getTriggerDepthLogPrefix() + ' TRIGGER: ' + OBJEC_TYPE + '   ' + Trigger.operationType + ' FINISH');
    }

    protected override void afterUpdate() {
        System.debug('----- ' + getTriggerDepthLogPrefix() + ' TRIGGER: ' + OBJEC_TYPE + '   ' + Trigger.operationType + ' START');

        switch on scenario {
            when SCENARIO_0 {
                afterUpdate0();
            }
            when SCENARIO_1 {
                afterUpdate1();
            }
            when SCENARIO_2 {
                afterUpdate2();
            }
        }

        System.debug('----- ' + getTriggerDepthLogPrefix() + ' TRIGGER: ' + OBJEC_TYPE + '   ' + Trigger.operationType + ' FINISH');
    }

    private void beforeUpdate0() {
        // После обновления TextField__c у дочернего объекта обновляется поле TextField__c у всех 
        // дочерних объектов того же родителя.
        
        for (TestObject__c testObject : testObjectsNew) {
            testObject.NumberField__c = testObject.TextField__c.length();
        }
    }

    private void afterUpdate0() {
        // После обновления TextField__c у дочернего объекта обновляется поле TextField__c у всех 
        // дочерних объектов того же родителя.

        List<TestObject__c> testObjectsForUpdate = new List<TestObject__c>();

        for(TestObject__c testObject : testObjectsNew) {
            testObjectsForUpdate.add(
                new TestObject__c(
                    Id = testObject.Id,
                    TextField__c = textFieldValueForTests,
                    TextAreaField__c = textFieldValueForTests
                )
            );
        }    

        update testObjectsForUpdate;
    }

    private void beforeUpdate1() {
        // После обновления TextField__c у дочернего объекта обновляется поле TextField__c у всех 
        // дочерних объектов того же родителя.

        for (TestObject__c testObject : testObjectsNew) {
            testObject.NumberField__c = testObject.TextField__c.length();
        }
    }

    private void afterUpdate1() {
        // После обновления TextField__c у дочернего объекта обновляется поле TextField__c у всех 
        // дочерних объектов того же родителя.

        Map<Id, TestObjectParent__c> parentsById = new Map<Id, TestObjectParent__c>([
            SELECT Id, TextField__c, NumberField__c, (SELECT Id, Name, NumberField__c FROM TestObjects__r)
            FROM TestObjectParent__c 
            WHERE Id IN (SELECT TestObjectParent__c FROM TestObject__c WHERE Id IN :testObjectsNew)
        ]);

        Map<Id, TestObject__c> testObgectByParentId = getTestObgectByParentId(testObjectsNew);

        List<TestObject__c> testObjectsForUpdate = new List<TestObject__c>();
        for(TestObjectParent__c parent : parentsById.values()) {
            for (TestObject__c testObjectForUpdate : parent.TestObjects__r) {
                // удаляем запись которая инициировала триггер
                // if (testObjectForUpdate.Id == testObgectByParentId.get(parent.Id).Id) {
                //     continue;
                // }

                testObjectForUpdate.TextField__c = testObgectByParentId.get(parent.Id).TextField__c;
                testObjectsForUpdate.add(testObjectForUpdate);
            }
        }

        System.debug('----- ' + getTriggerDepthLogPrefix() + ' testObjectsForUpdate.size(): ' + testObjectsForUpdate.size());

        update testObjectsForUpdate;
    }

    private void beforeUpdate2() {
        // После обновления TextField__c у дочернего объекта обновляется TextField__c у родителя и
        // затем у всех его дочерних объектов.

        for (TestObject__c testObject : testObjectsNew) {
            testObject.NumberField__c = testObject.TextField__c.length();
        }
    }

    private void afterUpdate2() {
        // После обновления TextField__c у дочернего объекта обновляется TextField__c у родителя и
        // затем у всех его дочерних объектов.

        Map<Id, TestObjectParent__c> parentsById = new Map<Id, TestObjectParent__c>([
            SELECT Id, TextField__c, NumberField__c
            FROM TestObjectParent__c 
            WHERE Id IN (SELECT TestObjectParent__c FROM TestObject__c WHERE Id IN :testObjectsNew)
        ]);

        for(TestObject__c testObject : testObjectsNew) {
            parentsById.get(testObject.TestObjectParent__c).TextField__c = testObject.TextField__c;
        }

        update parentsById.values();
    }

    private List<Id> getIdsFromList(List<SObject> records) {
        List<Id> ids = new List<Id>();

        for (SObject record : records) {
            ids.add(record.Id);
        }

        return ids;
    }

    private Map<Id, TestObject__c> getTestObgectByParentId(List<TestObject__c> records) {
        Map<Id, TestObject__c> testObgectByParentId = new Map<Id, TestObject__c>();

        for (TestObject__c record : records) {
            testObgectByParentId.put(record.TestObjectParent__c, record);
        }

        return testObgectByParentId;
    }
}