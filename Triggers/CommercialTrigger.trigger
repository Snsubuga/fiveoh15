trigger CommercialTrigger on Commercial__c (after update)  { 

	Map<Id, Commercial__c> newCommercials = Trigger.newMap;
	Map<Id, Commercial__c> oldCommercials = Trigger.oldMap;

	Set<String> commercialIds = new Set<String>();
	for (Commercial__c newCommercial : newCommercials.values()) {
		Commercial__c oldCommercial = oldCommercials.get(newCommercial.Id);
		if (oldCommercial.Running_Time_Seconds__c != newCommercial.Running_Time_Seconds__c) {
			commercialIds.add(newCommercial.id);
		}
	}
	//List<Commercial_Slot__c> commercialSlots = [Select Id, ];
}