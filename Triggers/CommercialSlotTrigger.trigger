trigger CommercialSlotTrigger on Commercial_Slot__c (after insert, after update, before delete, after undelete)  { 

	if (Trigger.isInsert) {
		List<Commercial_Slot__c> commercialSlots = Trigger.new;

		// Create a set to contain all the Commercials for the new commercial slots
		Set<String> commercialIds = new Set<String>();

		// Create a set to contain all Timeslots for the new commercial slots
		Set<String> timeslotIds = new Set<String>();

		// Create a map to contain commercial slots per commercial in the insert data
		Map<String, List<Commercial_Slot__c>> commercialsMap = new Map<String, List<Commercial_Slot__c>>();

		// Create a map to contain timeslots per commercial in the insert data
		Map<String, List<Commercial_Slot__c>> timeslotsMap = new Map<String, List<Commercial_Slot__c>>();

		// Iterate through the list of new commercial slots to populate the commercials id set
		for (Commercial_Slot__c cs : commercialSlots) {
			commercialIds.add(cs.Commercial__c);
			timeslotIds.add(cs.Timeslot__c);
			if (commercialsMap.get(cs.Commercial__c) == null) {
				List<Commercial_Slot__c> commercialSlotList = new List<Commercial_Slot__c>();
				commercialSlotList.add(cs);
				commercialsMap.put(cs.Commercial__c, commercialSlotList);
			}
			else {
				List<Commercial_Slot__c> commercialSlotList = commercialsMap.get(cs.Commercial__c);
				commercialSlotList.add(cs);
				commercialsMap.put(cs.Commercial__c, commercialSlotList);
			}
			if (timeslotsMap.get(cs.Timeslot__c) == null) {
				List<Commercial_Slot__c> commercialSlotList = new List<Commercial_Slot__c>();
				commercialSlotList.add(cs);
				timeslotsMap.put(cs.Timeslot__c, commercialSlotList);
			}
			else {
				List<Commercial_Slot__c> commercialSlotList = timeslotsMap.get(cs.Timeslot__c);
				commercialSlotList.add(cs);
				timeslotsMap.put(cs.Timeslot__c, commercialSlotList);
			}
		}

		// Get all the commercial data for the commercial slots
		List<Commercial__c> commercials = [SELECT Id, Broadcasts_Scheduled__c from Commercial__c where Id in:commercialIds];
		for (Commercial__c commercial : commercials) {
			List<Commercial_Slot__c> slots = commercialsMap.get(commercial.id);
			Integer numberOfBroadcasts = 0;
			for (Integer count = 0; count < slots.size(); count++) {
				numberOfBroadcasts += (Integer)slots[count].Number_of_Broadcasts__c;
			}
			// update the commercial with the sum total of the new commercial slots
			commercial.Broadcasts_Scheduled__c += numberOfBroadcasts; 
		}
		update commercials;

		// Get all the Timeslot data for the commercial slots
		List<Timeslot__c> timeSlots = [Select Id, Scheduled_Commercial_Time_Seconds__c, Program_Name__c from Timeslot__c where Id in:timeslotIds];
		for (Timeslot__c timeSlot : timeSlots) {
			List<Commercial_Slot__c> slots = timeslotsMap.get(timeSlot.id);
			for (Integer count = 0; count < slots.size(); count++) {
				Commercial_Slot__c cslot = slots[count];
				if (timeSlot.Scheduled_Commercial_Time_Seconds__c == null) {
					timeSlot.Scheduled_Commercial_Time_Seconds__c = 0;
				}
				timeSlot.Scheduled_Commercial_Time_Seconds__c += (Integer)slots[count].Total_Broadcast_Time_Seconds_c__c;
			}
		}
		update timeSlots;
	}
	 else if (Trigger.isDelete) {
		List<Commercial_Slot__c> commercialSlots = Trigger.old;

		// Create a set to contain all the Commercials for the deleted commercial slots
		Set<String> commercialIds = new Set<String>();

		// Create a set to contain Timeslot ids for the deleted commercial slots
		Set<String> timeSlotIds = new Set<String>();

		// Create a map to contain commercial slots per commercial to be deleted
		Map<String, List<Commercial_Slot__c>> commercialsMap = new Map<String, List<Commercial_Slot__c>>();

		Map<String, List<Commercial_Slot__c>> timeslotMap = new Map<String, List<Commercial_Slot__c>>();

		// Iterate through the list of new commercial slots to populate the commercials id set
		for (Commercial_Slot__c cs : commercialSlots) {
			commercialIds.add(cs.Commercial__c);
			timeSlotIds.add(cs.Timeslot__c);
			if (commercialsMap.get(cs.Commercial__c) == null) {
				List<Commercial_Slot__c> commercialSlotList = new List<Commercial_Slot__c>();
				commercialSlotList.add(cs);
				commercialsMap.put(cs.Commercial__c, commercialSlotList);
			}
			else {
				List<Commercial_Slot__c> commercialSlotList = commercialsMap.get(cs.Commercial__c);
				commercialSlotList.add(cs);
				commercialsMap.put(cs.Commercial__c, commercialSlotList);
			}

			if (timeslotMap.get(cs.Timeslot__c) == null) {
				List<Commercial_Slot__c> commercialSlotList = new List<Commercial_Slot__c>();
				commercialSlotList.add(cs);
				timeslotMap.put(cs.Timeslot__c, commercialSlotList);
			}
			else {
				List<Commercial_Slot__c> commercialSlotList = timeslotMap.get(cs.Timeslot__c);
				commercialSlotList.add(cs);
				timeslotMap.put(cs.Timeslot__c, commercialSlotList);
			}
		}

		// Get all the commercial data for the commercial slots
		List<Commercial__c> commercials = [SELECT Id, Broadcasts_Scheduled__c from Commercial__c where Id in:commercialIds];
		for (Commercial__c commercial : commercials) {
			List<Commercial_Slot__c> slots = commercialsMap.get(commercial.id);
			Integer numberOfBroadcasts = 0;
			for (Integer count = 0; count < slots.size(); count++) {
				numberOfBroadcasts += (Integer)slots[count].Number_of_Broadcasts__c;
			}
			// update the commercial with the sum total of the new commercial slots
			commercial.Broadcasts_Scheduled__c -= numberOfBroadcasts; 
		}
		update commercials;

		// Get all the timeslots data
		List<Timeslot__c> timeSlots = [Select Id, Scheduled_Commercial_Time_Seconds__c, Program_Name__c from Timeslot__c where Id in:timeslotIds];
		for (Timeslot__c timeSlot : timeSlots) {
			List<Commercial_Slot__c> slots = timeslotMap.get(timeSlot.id);
			for (Integer count = 0; count < slots.size(); count++) {
				Commercial_Slot__c cslot = slots[count];
				if (timeSlot.Scheduled_Commercial_Time_Seconds__c == null) {
					timeSlot.Scheduled_Commercial_Time_Seconds__c = 0;
				}
				timeSlot.Scheduled_Commercial_Time_Seconds__c -= (Integer)slots[count].Total_Broadcast_Time_Seconds_c__c;
			}
		}
		update timeSlots;
	 }
	 else if (Trigger.isUndelete) {
		List<Commercial_Slot__c> commercialSlots = Trigger.new;

		// Create a set to contain all the Commercials for the new commercial slots
		Set<String> commercialIds = new Set<String>();

		Set<String> timeslotIds = new Set<String>();

		// Create a map to contain commercial slots per commercial in the insert data
		Map<String, List<Commercial_Slot__c>> commercialsMap = new Map<String, List<Commercial_Slot__c>>();

		Map<String, List<Commercial_Slot__c>> timeslotsMap = new Map<String, List<Commercial_Slot__c>>();

		// Iterate through the list of new commercial slots to populate the commercials id set
		for (Commercial_Slot__c cs : commercialSlots) {
			commercialIds.add(cs.Commercial__c);
			timeslotIds.add(cs.Timeslot__c);
			if (commercialsMap.get(cs.Commercial__c) == null) {
				List<Commercial_Slot__c> commercialSlotList = new List<Commercial_Slot__c>();
				commercialSlotList.add(cs);
				commercialsMap.put(cs.Commercial__c, commercialSlotList);
			}
			else {
				List<Commercial_Slot__c> commercialSlotList = commercialsMap.get(cs.Commercial__c);
				commercialSlotList.add(cs);
				commercialsMap.put(cs.Commercial__c, commercialSlotList);
			}
			if (timeslotsMap.get(cs.Timeslot__c) == null) {
				List<Commercial_Slot__c> commercialSlotList = new List<Commercial_Slot__c>();
				commercialSlotList.add(cs);
				timeslotsMap.put(cs.Timeslot__c, commercialSlotList);
			}
			else {
				List<Commercial_Slot__c> commercialSlotList = timeslotsMap.get(cs.Timeslot__c);
				commercialSlotList.add(cs);
				timeslotsMap.put(cs.Timeslot__c, commercialSlotList);
			}
		}

		// Get all the commercial data for the commercial slots
		List<Commercial__c> commercials = [SELECT Id, Broadcasts_Scheduled__c from Commercial__c where Id in:commercialIds];
		for (Commercial__c commercial : commercials) {
			List<Commercial_Slot__c> slots = commercialsMap.get(commercial.id);
			Integer numberOfBroadcasts = 0;
			for (Integer count = 0; count < slots.size(); count++) {
				numberOfBroadcasts += (Integer)slots[count].Number_of_Broadcasts__c;
			}
			// update the commercial with the sum total of the new commercial slots
			commercial.Broadcasts_Scheduled__c += numberOfBroadcasts; 
		}
		update commercials;

		// Get all the timeslot data
		List<Timeslot__c> timeslots = [Select Id, Scheduled_Commercial_Time_Seconds__c from Timeslot__c
			where Id in :timeslotIds];

		for (Timeslot__c timeslot : timeslots) {
			List<Commercial_Slot__c> slots = timeslotsMap.get(timeslot.id);
			for (Integer count = 0; count < slots.size(); count++) {
				timeslot.Scheduled_Commercial_Time_Seconds__c += (Integer)slots[count].Total_Broadcast_Time_Seconds_c__c;
			}
		}
		update timeslots;
	 }
	 else if (Trigger.isUpdate) {
		Map<Id, Commercial_Slot__c> oldData = Trigger.oldMap;
		Map<Id, Commercial_Slot__c> newData = Trigger.newMap;

		// Check if number of broadcasts has changed and if so, collect all the affected commercials
		Set<String> commercialIds = new Set<String>();
		Map<String, List<Commercial_Slot__c>> commercialsMap = new Map<String, List<Commercial_Slot__c>>();

		Set<String> timeslotIds = new Set<String>();
		Map<String, List<Commercial_Slot__c>> timeslotsMap = new Map<String, List<Commercial_Slot__c>>();

		for (String slotId : newData.keyset()) {
			Commercial_Slot__c oldSlot = oldData.get(slotId);
			Commercial_Slot__c newSlot = newData.get(slotId);
			if (oldSlot.Commercial__c == newSlot.Commercial__c) {

				if (oldSlot.Number_of_Broadcasts__c != newSlot.Number_of_Broadcasts__c) {

					commercialIds.add(newSlot.Commercial__c);

					if (commercialsMap.get(newSlot.Commercial__c) == null) {
						List<Commercial_Slot__c> commercialSlotList = new List<Commercial_Slot__c>();
						commercialSlotList.add(newSlot);
						commercialsMap.put(newSlot.Commercial__c, commercialSlotList);
					}	
					else {
						List<Commercial_Slot__c> commercialSlotList = commercialsMap.get(newSlot.Commercial__c);
						commercialSlotList.add(newSlot);
						commercialsMap.put(newSlot.Commercial__c, commercialSlotList);
					}				
				}
			}
			else if (oldSlot.Commercial__c != newSlot.Commercial__c) {
				commercialIds.addAll(new Set<String> {oldSlot.Commercial__c, newSlot.Commercial__c});
			}

			// Operations related to the timeslot
			if (oldSlot.Timeslot__c == newSlot.Timeslot__c) {
				if (oldSlot.Number_of_Broadcasts__c != newSlot.Number_of_Broadcasts__c) {
					timeslotIds.add(newSlot.Timeslot__c);
				}
			}
			else if (oldSlot.Timeslot__c != newSlot.Timeslot__c) {
				timeslotIds.addAll(new Set<String> {oldSlot.Timeslot__c, newSlot.Timeslot__c});
			}
			
		}
		if (commercialIds.size() > 0) {
			Map<Id, Commercial__c> commercials = new Map<Id, Commercial__c>([SELECT Id, Broadcasts_Scheduled__c from Commercial__c where Id in:commercialIds]);

			// Iterate through the commercials, deducting the old values of 
			// number of broadcasts and then adding the new values of the broadcasts
			// also handle the change of commercial
			for (String slotId : newData.keyset()) {
				Commercial_Slot__c oldSlot = oldData.get(slotId);
				Commercial_Slot__c newSlot = newData.get(slotId);
				if (oldSlot.Commercial__c == newSlot.Commercial__c) {
					Commercial__c commercial = commercials.get(newSlot.Commercial__c);
					commercial.Broadcasts_Scheduled__c = commercial.Broadcasts_Scheduled__c - oldSlot.Number_of_Broadcasts__c + newSlot.Number_of_Broadcasts__c;
				}
				else if (oldSlot.Commercial__c != newSlot.Commercial__c) {
					Commercial__c oldCommercial = commercials.get(oldSlot.Commercial__c);
					Commercial__c newCommercial = commercials.get(newSlot.Commercial__c);

					oldCommercial.Broadcasts_Scheduled__c = oldCommercial.Broadcasts_Scheduled__c - oldSlot.Number_of_Broadcasts__c;
					newCommercial.Broadcasts_Scheduled__c = newCommercial.Broadcasts_Scheduled__c + newSlot.Number_of_Broadcasts__c;
				}
			}
			update commercials.values();
		}
		if (timeslotIds.size() > 0) {
			Map<Id, Timeslot__c> timeslots = new Map<Id, Timeslot__c>([SELECT Id, Scheduled_Commercial_Time_Seconds__c from Timeslot__c where Id in:timeslotIds]);

			// Iterate through the timeslots, deducting the old values of 
			// total broadcast time and then adding the new values of the broadcast time
			// also handle the change of timeslot
			for (String slotId : newData.keyset()) {
				Commercial_Slot__c oldSlot = oldData.get(slotId);
				Commercial_Slot__c newSlot = newData.get(slotId);
				if (oldSlot.Timeslot__c == newSlot.Timeslot__c) {
					if (oldSlot.Number_of_Broadcasts__c != newSlot.Number_of_Broadcasts__c) {
						Timeslot__c timeslot = timeslots.get(newSlot.Timeslot__c);
						timeslot.Scheduled_Commercial_Time_Seconds__c = timeslot.Scheduled_Commercial_Time_Seconds__c - oldSlot.Total_Broadcast_Time_Seconds_c__c + newSlot.Total_Broadcast_Time_Seconds_c__c;
					}
				}
				else if (oldSlot.Timeslot__c != newSlot.Timeslot__c) {
					Timeslot__c oldTimeslot = timeslots.get(oldSlot.Timeslot__c);
					Timeslot__c newTimeslot = timeslots.get(newSlot.Timeslot__c);

					oldTimeslot.Scheduled_Commercial_Time_Seconds__c -= oldSlot.Total_Broadcast_Time_Seconds_c__c;
					newTimeslot.Scheduled_Commercial_Time_Seconds__c += newSlot.Total_Broadcast_Time_Seconds_c__c;
				}
			}
			update timeslots.values();
		}
	 }
	
}