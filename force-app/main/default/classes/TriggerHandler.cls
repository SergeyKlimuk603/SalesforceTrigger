
public virtual class TriggerHandler {
    protected final SObjectType OBJEC_TYPE;
    protected TriggerAction ACTION_TYPE;
    public static TestScenario scenario = TestScenario.SCENARIO_0;
    public static Integer triggerDepth = 0; // Просто индикатор глубины рекурсии триггера, на логику не влияет.

    private static Map<SObjectType, Map<TriggerAction, Set<Id>>> allProcessedRecords = 
        new Map<SObjectType, Map<TriggerAction, Set<Id>>>();
    public static Set<SObjectType> disabledTriggers = new Set<SObjectType>();

    public TriggerHandler() {
        ACTION_TYPE = getActionType();
    }

    public void run() {
        if (isTriggerAvailable()) {
            return;
        }

        List<SObject> oldUnprocessedRecords = new List<SObject>();
        List<SObject> newUnprocessedRecords = new List<SObject>();

        switch on Trigger.operationType {
            when BEFORE_INSERT {
                this.beforeInsert(Trigger.new);
            }
            when AFTER_INSERT {
                this.afterInsert(Trigger.new, Trigger.newMap);
            }
            when BEFORE_UPDATE {
                triggerDepth++;
                System.debug('------Start Changed Record Finding ' + Trigger.operationType 
                    + '. triggerDepth: ' + triggerDepth);

                if (filloutUnprocessedRecordsForUpdate(oldUnprocessedRecords, newUnprocessedRecords)) {
                    triggerDepth--;
                    return;
                }

                System.debug('-----End Changed Record Finding ' + Trigger.operationType 
                    + '. Records for ' + Trigger.operationType + ': ' + newUnprocessedRecords.size());

                Map<Id, SObject> oldUnprocessedRecordsMap = new Map<Id, SObject>(oldUnprocessedRecords);
                allProcessedRecords.get(OBJEC_TYPE).get(ACTION_TYPE).addAll(oldUnprocessedRecordsMap.keySet());

                this.beforeUpdate(newUnprocessedRecords, oldUnprocessedRecordsMap);

                allProcessedRecords.get(OBJEC_TYPE).get(ACTION_TYPE).removeAll(oldUnprocessedRecordsMap.keySet());

                triggerDepth--;
            }
            when AFTER_UPDATE {
                triggerDepth++;
                System.debug('------Start Changed Record Finding ' + Trigger.operationType 
                    + '. triggerDepth: ' + triggerDepth);

                if (filloutUnprocessedRecordsForUpdate(oldUnprocessedRecords, newUnprocessedRecords)) {
                    triggerDepth--;
                    return;
                }

                System.debug('-----End Changed Record Finding ' + Trigger.operationType 
                    + '. Records for ' + Trigger.operationType + ': ' + newUnprocessedRecords.size());

                Map<Id, SObject> oldUnprocessedRecordsMap = new Map<Id, SObject>(oldUnprocessedRecords);
                allProcessedRecords.get(OBJEC_TYPE).get(ACTION_TYPE).addAll(oldUnprocessedRecordsMap.keySet());

                this.afterUpdate(newUnprocessedRecords, oldUnprocessedRecordsMap);

                allProcessedRecords.get(OBJEC_TYPE).get(ACTION_TYPE).removeAll(oldUnprocessedRecordsMap.keySet());

                triggerDepth--;
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

    protected virtual void beforeInsert(List<SObject> newUnprocessedRecords) {}
    protected virtual void afterInsert(List<SObject> newUnprocessedRecords, Map<Id, SObject> newUnprocessedRecordsMap) {}
    protected virtual void beforeUpdate(List<SObject> newUnprocessedRecords, Map<Id, SObject> oldUnprocessedRecordsMap) {}
    protected virtual void afterUpdate(List<SObject> newUnprocessedRecords, Map<Id, SObject> oldUnprocessedRecordsMap) {}
    protected virtual void beforeDelete(List<SObject> oldUnprocessedRecords, Map<Id, SObject> oldUnprocessedRecordsMap) {}
    protected virtual void afterDelete(List<SObject> oldUnprocessedRecords, Map<Id, SObject> oldUnprocessedRecordsMap) {}
    protected virtual void afterUndelete(List<SObject> newUnprocessedRecords, Map<Id, SObject> newUnprocessedRecordsMap) {}

    private Boolean isTriggerAvailable() {
        return disabledTriggers.contains(OBJEC_TYPE);
    }

    private TriggerAction getActionType() {
        TriggerAction action;
        switch on Trigger.operationType {
            when BEFORE_INSERT, AFTER_INSERT {
                action = TriggerAction.INSERT_ACTION;
            }
            when BEFORE_UPDATE, AFTER_UPDATE {
                action = TriggerAction.UPDATE_ACTION;
            }
            when BEFORE_DELETE, AFTER_DELETE {
                action = TriggerAction.DELETE_ACTION;
            }
            when AFTER_UNDELETE {
                action = TriggerAction.UNDELETE_ACTION;
            }
        }

        return action;
    }

    private Boolean filloutUnprocessedRecordsForUpdate(
        List<SObject> oldUnprocessedRecords, 
        List<SObject> newUnprocessedRecords
    ) {
        Set<Id> processedRecords = getProcessedRecords();
        for (SObject oldRecord : Trigger.old) {
            SObject newRecord = Trigger.newMap.get(oldRecord.Id);

            if (!processedRecords.contains(newRecord.Id)) {
                oldUnprocessedRecords.add(oldRecord);
                newUnprocessedRecords.add(newRecord);
            }
        }

        System.debug('-----newUnprocessedRecords.size(): ' + newUnprocessedRecords.size());

        Boolean hasNoUnprocessedRecords = newUnprocessedRecords.isEmpty();

        return hasNoUnprocessedRecords;
    }

    private Set<Id> getProcessedRecords() {
        if (allProcessedRecords.get(OBJEC_TYPE) == null) {
            allProcessedRecords.put(OBJEC_TYPE, new Map<TriggerAction, Set<Id>>());
        }

        if (allProcessedRecords.get(OBJEC_TYPE).get(ACTION_TYPE) == null) {
            allProcessedRecords.get(OBJEC_TYPE).put(ACTION_TYPE, new Set<Id>());
        }
        
        return allProcessedRecords.get(OBJEC_TYPE).get(ACTION_TYPE);
    }

    public enum TriggerAction {INSERT_ACTION, UPDATE_ACTION, DELETE_ACTION, UNDELETE_ACTION}
}
