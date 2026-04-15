trigger LeadTrigger on Lead (after insert, before update, after update) {
    if(trigger.isBefore){
        if(trigger.isUpdate){
            LeadTriggerHandler.onBeforeUpdate(trigger.new, trigger.oldMap);
        }
    }
    
    if(trigger.isAfter){
        if(trigger.isInsert){
            LeadTriggerHandler.onAfterInsert(trigger.new);
        }

        if(trigger.isUpdate){
            LeadTriggerHandler.onAfterUpdate(trigger.new, trigger.oldMap);
        }
    }
}