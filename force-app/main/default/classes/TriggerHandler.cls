
public virtual class TriggerHandler {
    protected final SObjectType OBJEC_TYPE;
   
    public static Set<SObjectType> disabledTriggers = new Set<SObjectType>();

    public void run() {
        if (isTriggerAvailable()) {
            return;
        }

        List<SObject> oldChangedObjects = new List<SObject>();
        List<SObject> newChangedObjects = new List<SObject>();
        
        switch on Trigger.operationType {
            when BEFORE_INSERT {
                this.beforeInsert(Trigger.new);
            }
            when AFTER_INSERT {
                this.afterInsert(Trigger.new, Trigger.newMap);
            }
            when BEFORE_UPDATE {
                System.debug('-----Start Changed Record Finding before update');

                if (filloutChangedRecordsForUpdate(oldChangedObjects, newChangedObjects)) {
                    return;
                }

                System.debug('-----End Changed Record Finding before update. Records for beforeUpdate: ' + newChangedObjects.size());

                this.beforeUpdate(newChangedObjects, new Map<Id, SObject>(oldChangedObjects));
            }
            when AFTER_UPDATE {
                System.debug('-----Start Changed Record Finding after update');
    
                if (filloutChangedRecordsForUpdate(oldChangedObjects, newChangedObjects)) {
                    return;
                }

                System.debug('-----End Changed Record Finding after update. Records for afterUpdate: ' + newChangedObjects.size());

                this.afterUpdate(newChangedObjects, new Map<Id, SObject>(oldChangedObjects));
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

    protected virtual void beforeInsert(List<SObject> newChangedObjects) {}
    protected virtual void afterInsert(List<SObject> newChangedObjects, Map<Id, SObject> newChangedObjectsMap) {}
    protected virtual void beforeUpdate(List<SObject> newChangedObjects, Map<Id, SObject> oldChangedObjectsMap) {}
    protected virtual void afterUpdate(List<SObject> newChangedObjects, Map<Id, SObject> oldChangedObjectsMap) {}
    protected virtual void beforeDelete(List<SObject> oldChangedObjects, Map<Id, SObject> oldChangedObjectsMap) {}
    protected virtual void afterDelete(List<SObject> oldChangedObjects, Map<Id, SObject> oldChangedObjectsMap) {}
    protected virtual void afterUndelete(List<SObject> newChangedObjects, Map<Id, SObject> newChangedObjectsMap) {}

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

    private Boolean areRecordsNotEquals(SObject record, SObject newRecord) {
        List<String> ommitedKeys = new List<String>{
            'LastModifiedDate',
            'SystemModstamp'
        };
        Map<String, Object> recordMap = record.getPopulatedFieldsAsMap();
        Map<String, Object> newRecordMap = newRecord.getPopulatedFieldsAsMap();
        Set<String> allKeys = new Set<String>();
        allKeys.addAll(recordMap.keySet());
        allKeys.addAll(newRecordMap.keySet());
        // System.debug(
        //     + '---record{TextField__c = '  + recordMap.get('TextField__c') + ', NumberField__c = ' 
        //         + recordMap.get('NumberField__c') + '}   !!!   '
        //     + '---newRecordMap{TextField__c = '  + newRecordMap.get('TextField__c') + ', NumberField__c = ' 
        //         + newRecordMap.get('NumberField__c') + '}'
        // );
        
        for (String key : allKeys) {
            if (ommitedKeys.contains(key)) {
                continue;
            }

            if (recordMap.get(key) != newRecordMap.get(key)) {
                return true;
            }
        }

        return false;
    }
}
