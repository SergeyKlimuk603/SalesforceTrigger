public virtual class TriggerHandler {
    protected final SObjectType OBJEC_TYPE;
    protected TriggerAction ACTION_TYPE;
    protected Integer ACTIONS_MAX_DEPTH = 5;
    public static Integer triggerDepth = 0; // Регулятор глубины рекурсии
    public static TestScenario scenario = TestScenario.SCENARIO_0;

    //private static Map<SObjectType, Map<TriggerAction, Integer>> runingActionsDepth = new Map<SObjectType, Map<TriggerAction, Integer>>();
    public static Set<SObjectType> disabledTriggers = new Set<SObjectType>();

    public TriggerHandler() {
        ACTION_TYPE = getActionType();
    }

    public void run() {
        if (isTriggerNotAvailable()) {
            return;
        }

        // Integer depthCount = runingActionsDepth.get(OBJEC_TYPE).get(ACTION_TYPE);
        // depthCount++;
        // runingActionsDepth.get(OBJEC_TYPE).put(ACTION_TYPE, depthCount);
        //System.debug('------depthCount: ' + depthCount);

        switch on Trigger.operationType {
            when BEFORE_INSERT {
                this.beforeInsert();
            }
            when AFTER_INSERT {
                this.afterInsert();
            }
            when BEFORE_UPDATE {
                triggerDepth++;
                logTriggerDepth();

                this.beforeUpdate();

                triggerDepth--;
                logTriggerDepth();
            }
            when AFTER_UPDATE {
                triggerDepth++;
                logTriggerDepth();

                this.afterUpdate();

                triggerDepth--;
                logTriggerDepth();
            }
            when BEFORE_DELETE {
                this.beforeDelete();
            }
            when AFTER_DELETE {
                this.afterDelete();
            }
            when AFTER_UNDELETE {
                this.afterUndelete();
            }
        }

        // depthCount--;
        // runingActionsDepth.get(OBJEC_TYPE).put(ACTION_TYPE, depthCount);
    }

    protected virtual void beforeInsert() {}
    protected virtual void afterInsert() {}
    protected virtual void beforeUpdate() {}
    protected virtual void afterUpdate() {}
    protected virtual void beforeDelete() {}
    protected virtual void afterDelete() {}
    protected virtual void afterUndelete() {}

    private Boolean isTriggerNotAvailable() {
        // if (runingActionsDepth.get(OBJEC_TYPE) == null) {
        //     runingActionsDepth.put(OBJEC_TYPE, new Map<TriggerAction, Integer>());
        // }

        // if (runingActionsDepth.get(OBJEC_TYPE).get(ACTION_TYPE) == null) {
        //     runingActionsDepth.get(OBJEC_TYPE).put(ACTION_TYPE, 0);
        // }

        return disabledTriggers.contains(OBJEC_TYPE)
            || triggerDepth >= ACTIONS_MAX_DEPTH;
            // || runingActionsDepth.get(OBJEC_TYPE).contains(ACTION_TYPE)
            // || runingActionsDepth.get(OBJEC_TYPE).get(ACTION_TYPE) >= ACTIONS_MAX_DEPTH
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

    public enum TriggerAction {INSERT_ACTION, UPDATE_ACTION, DELETE_ACTION, UNDELETE_ACTION}
}
 