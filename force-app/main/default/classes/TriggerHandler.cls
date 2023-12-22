
public virtual class TriggerHandler {
    protected final SObjectType OBJEC_TYPE;
    public static TestScenario scenario = TestScenario.SCENARIO_3;
    public static Integer triggerDepth = 0; // Просто индикатор глубины рекурсии триггера, на логику не влияет.
   
    public static Set<SObjectType> disabledTriggers = new Set<SObjectType>();

    public void run() {
        if (isTriggerAvailable()) {
            return;
        }

        List<SObject> oldChangedRecords = new List<SObject>();
        List<SObject> newChangedRecords = new List<SObject>();
        
        switch on Trigger.operationType {
            when BEFORE_INSERT {
                this.beforeInsert(Trigger.new);
            }
            when AFTER_INSERT {
                this.afterInsert(Trigger.new, Trigger.newMap);
            }
            when BEFORE_UPDATE {
                triggerDepth++;
                logTriggerDepth();

                //System.debug('------ ' + getTriggerDepthLogPrefix() + ' Start Changed Record Finding before update.');

                if (filloutChangedRecordsForUpdate(oldChangedRecords, newChangedRecords)) {
                    triggerDepth--;
                    logTriggerDepth();
                    System.debug('----- ' + getTriggerDepthLogPrefix() + ' Changed records for beforeUpdate: ' + newChangedRecords.size());
                    return;
                }

                System.debug('----- ' + getTriggerDepthLogPrefix() + ' Changed records for beforeUpdate: ' + newChangedRecords.size());

                //System.debug('----- ' + getTriggerDepthLogPrefix() + ' End Changed Record Finding before update. Records for beforeUpdate: ' + newChangedRecords.size());

                this.beforeUpdate(newChangedRecords, new Map<Id, SObject>(oldChangedRecords));

                triggerDepth--;
                logTriggerDepth();
            }
            when AFTER_UPDATE {
                triggerDepth++;
                logTriggerDepth();

                //System.debug('------ ' + getTriggerDepthLogPrefix() + ' Start Changed Record Finding after update');
    
                if (filloutChangedRecordsForUpdate(oldChangedRecords, newChangedRecords)) {
                    triggerDepth--;
                    logTriggerDepth();
                    System.debug('----- ' + getTriggerDepthLogPrefix() + ' Changed records afterUpdate: ' + newChangedRecords.size());
                    return;
                }

                System.debug('----- ' + getTriggerDepthLogPrefix() + ' Changed records afterUpdate: ' + newChangedRecords.size());
                //System.debug('----- ' + getTriggerDepthLogPrefix() + ' End Changed Record Finding after update. Records for afterUpdate: ' + newChangedRecords.size());

                this.afterUpdate(newChangedRecords, new Map<Id, SObject>(oldChangedRecords));

                triggerDepth--;
                logTriggerDepth();
            }
            when BEFORE_DELETE {
                this.beforeDelete(Trigger.old, Trigger.oldMap);
            }
            when AFTER_DELETE {
                this.afterDelete(Trigger.old, Trigger.oldMap);
            }
            when AFTER_UNDELETE {
                this.afterUndelete(Trigger.new, Trigger.newMap);
            }
        }
    }

    protected virtual void beforeInsert(List<SObject> newChangedRecords) {}
    protected virtual void afterInsert(List<SObject> newChangedRecords, Map<Id, SObject> newChangedRecordsMap) {}
    protected virtual void beforeUpdate(List<SObject> newChangedRecords, Map<Id, SObject> oldChangedRecordsMap) {}
    protected virtual void afterUpdate(List<SObject> newChangedRecords, Map<Id, SObject> oldChangedRecordsMap) {}
    protected virtual void beforeDelete(List<SObject> oldChangedRecords, Map<Id, SObject> oldChangedRecordsMap) {}
    protected virtual void afterDelete(List<SObject> oldChangedRecords, Map<Id, SObject> oldChangedRecordsMap) {}
    protected virtual void afterUndelete(List<SObject> newChangedRecords, Map<Id, SObject> newChangedRecordsMap) {}

    private Boolean isTriggerAvailable() {
        return disabledTriggers.contains(OBJEC_TYPE);
    }  

    private Boolean filloutChangedRecordsForUpdate(
        List<SObject> changedRecordsOld, 
        List<SObject> changedRecordsNew
    ) {

        for (SObject oldRecord : Trigger.old) {
            SObject newRecord = Trigger.newMap.get(oldRecord.Id);

            if (areRecordsNotEquals(oldRecord, newRecord)) {
                changedRecordsOld.add(oldRecord);
                changedRecordsNew.add(newRecord);
            }
        }

        Boolean hasNoChangedRecords = changedRecordsNew.isEmpty();

        return hasNoChangedRecords;
    }

    private Boolean areRecordsNotEquals(SObject oldRecord, SObject newRecord) {
        List<String> ommitedKeys = new List<String>{
            'LastModifiedDate',
            'SystemModstamp'
        };

        Set<String> allKeys = new Set<String>();
        allKeys.addAll(oldRecord.getPopulatedFieldsAsMap().keySet());
        allKeys.addAll(newRecord.getPopulatedFieldsAsMap().keySet());
        allKeys.removeAll(ommitedKeys);
        
        for (String key : allKeys) {
            if (oldRecord.get(key) != newRecord.get(key)) {
                return true;
            }
        }

        return false;
    }

    private Boolean areRecordsNotEqualsV0(SObject oldRecord, SObject newRecord) {
        List<String> ommitedKeys = new List<String>{
            'LastModifiedDate',
            'SystemModstamp'
        };

        Map<String, Object> oldRecordMap = oldRecord.getPopulatedFieldsAsMap();
        Map<String, Object> newRecordMap = newRecord.getPopulatedFieldsAsMap();
        Set<String> allKeys = new Set<String>();
        allKeys.addAll(oldRecordMap.keySet());
        allKeys.addAll(newRecordMap.keySet());
        // System.debug(
        //     + '---oldRecord{TextField__c = '  + oldRecordMap.get('TextField__c') + ', NumberField__c = ' 
        //         + oldRecordMap.get('NumberField__c') + '}   !!!   '
        //     + '---newRecordMap{TextField__c = '  + newRecordMap.get('TextField__c') + ', NumberField__c = ' 
        //         + newRecordMap.get('NumberField__c') + '}'
        // );
        
        for (String key : allKeys) {
            if (ommitedKeys.contains(key)) {
                continue;
            }

            if (oldRecordMap.get(key) != newRecordMap.get(key)) {
                return true;
            }
        }

        return false;
    }

    // Работает нестабильно
    private Boolean areRecordsNotEqualsV1(SObject oldRecord, SObject newRecord) {
        return oldRecord.clone(false, false, false, false)
            != newRecord.clone(false, false, false, false);

        // return oldRecord != newRecord;
    }

    private void logTriggerDepth() {
        System.debug('------- ' + getTriggerDepthLogPrefix() 
            + OBJEC_TYPE + '__' + Trigger.operationType + ' triggerDepth: ' + triggerDepth
        );
    }

    protected String getTriggerDepthLogPrefix() {
        String depthPrefix = '';

        for (Integer i = 0; i < triggerDepth; i++) {
            depthPrefix += '___________ ';
        }

        return depthPrefix;
    }
}
