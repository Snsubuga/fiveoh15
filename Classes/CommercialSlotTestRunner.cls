@isTest
private class CommercialSlotTestRunner { 

	@testSetup static void setup() {

		// Create Users
		List<Profile> userProfiles = [SELECT Id FROM Profile WHERE Name in ('Broadcast Planner', 'Network Executive') 
			order by Name asc];

		List<User> users = new List<User>();
		for (Integer index = 0; index < 2; index++) {
			User user = new User(Alias = 'user'+index, Email='user'+index+'@testuser.org', 
			EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
			LocaleSidKey='en_US', ProfileId = userProfiles[index].Id, 
			TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com'+index);
			users.add(user);
		}
		insert users;

		// Create an account
		Account testAccount = new Account(Name='Test Account');
		testAccount.OwnerId = users[0].Id;
		insert testAccount;
		List<Commercial__c> commercials = new List<Commercial__c>();
		for (Integer count = 1; count <= 5; count++) {
			Commercial__c commercial = new Commercial__c();
			commercial.OwnerId = users[0].Id;
			commercial.Name = 'Commercial'+count;
			commercial.Account__c = testAccount.Id;
			commercial.Broadcast_Start_Date__c = Date.today();
			commercial.Broadcast_Stop_Date__c = Date.today().addDays(10);
			commercial.Contracted_Broadcast_Time_Seconds__c = 200;
			commercial.Running_Time_Seconds__c = 20;
			commercial.Broadcasts_Scheduled__c = 0;
			commercials.add(commercial);
		}
		insert commercials;
		List<Timeslot__c> timeSlots = new List<Timeslot__c>();
		for (Integer count = 1; count <= 3; count++) {
			Timeslot__c timeSlot = new Timeslot__c();
			timeSlot.Allowed_Commercial_Time_Seconds__c = 600;
			timeSlot.Program_Genre__c = 'Action';
			timeSlot.Program_Name__c = 'Movie Night'+count;
			timeSlot.Timeslot_Date_Time__c = Datetime.now().addHours(count);
			timeSlot.Scheduled_Commercial_Time_Seconds__c = 0;
			timeSlots.add(timeSlot);
		}
		insert timeSlots;

		// Create some commercialslots
		List<Commercial_Slot__c> commercialSlots = new List<Commercial_Slot__c>();
		Commercial_Slot__c slot1 = new Commercial_Slot__c();
		slot1.Commercial__c = commercials[0].id;
		slot1.Timeslot__c = timeSlots[0].id;
		slot1.Date_Time__c = Datetime.now().addHours(1);
		slot1.Number_of_Broadcasts__c = 4;
		
		Commercial_Slot__c slot2 = new Commercial_Slot__c();
		slot2.Commercial__c = commercials[1].id;
		slot2.Timeslot__c = timeSlots[0].id;
		slot2.Date_Time__c = Datetime.now().addHours(2);
		slot2.Number_of_Broadcasts__c = 2;

		Commercial_Slot__c slot3 = new Commercial_Slot__c();
		slot3.Commercial__c = commercials[0].id;
		slot3.Timeslot__c = timeSlots[1].id;
		slot3.Date_Time__c = Datetime.now().addHours(3);
		slot3.Number_of_Broadcasts__c = 3;

		commercialSlots.add(slot1);
		commercialSlots.add(slot2);
		commercialSlots.add(slot3);
		insert commercialSlots;
	}

	/**
	* Checks the affected commercials and Timeslots after an insert
	* to see that the Number of Broadcasts scheduled has increased
	*/
	@isTest static void testBulkInsert() {

		Commercial__c commercial1 = [Select Broadcasts_Scheduled__c from Commercial__c where Name ='Commercial1'];
		Commercial__c commercial2 = [Select Broadcasts_Scheduled__c from Commercial__c where Name ='Commercial2'];
		Timeslot__c timeSlot = [Select Scheduled_Commercial_Time_Seconds__c from Timeslot__c where Program_Name__c = 'Movie Night1'];
		System.assertEquals(7, commercial1.Broadcasts_Scheduled__c);
		System.assertEquals(2, commercial2.Broadcasts_Scheduled__c);
		System.assertEquals(120, timeSlot.Scheduled_Commercial_Time_Seconds__c);
	}

	@isTest static void testDeletion() {
		List<Commercial_Slot__c> slot3 = [Select Id from Commercial_Slot__c where Number_of_Broadcasts__c = 3 and Commercial__r.Name = 'Commercial1'];
		delete slot3;
		Commercial__c commercial1 = [Select Broadcasts_Scheduled__c from Commercial__c where Name ='Commercial1'];
		System.assertEquals(4, commercial1.Broadcasts_Scheduled__c);
		Timeslot__c timeSlot = [Select Scheduled_Commercial_Time_Seconds__c from Timeslot__c where Program_Name__c = 'Movie Night2'];
		System.assertEquals(0, timeSlot.Scheduled_Commercial_Time_Seconds__c);
	}

	@isTest static void testUndelete() {
		List<Commercial_Slot__c> slot3 = [Select Id from Commercial_Slot__c where Number_of_Broadcasts__c = 3 and Commercial__r.Name = 'Commercial1'];
		Id slot3id = slot3[0].id;
		delete slot3;
		undelete new Commercial_Slot__c(Id = slot3id);
		Commercial__c commercial1 = [Select Broadcasts_Scheduled__c from Commercial__c where Name ='Commercial1'];
		System.assertEquals(7, commercial1.Broadcasts_Scheduled__c);
		Timeslot__c timeSlot = [Select Scheduled_Commercial_Time_Seconds__c from Timeslot__c where Program_Name__c = 'Movie Night2'];
		System.assertEquals(60, timeSlot.Scheduled_Commercial_Time_Seconds__c);
	}

	/**
	* @description 
	*/
	@isTest static void testUpdateOfCommercial() {
		List<Commercial_Slot__c> slot2 = [Select Id, Commercial__c from Commercial_Slot__c where Number_of_Broadcasts__c = 2 and Commercial__r.Name = 'Commercial2'];
		Commercial__c commercial1 = [Select Id, Broadcasts_Scheduled__c from Commercial__c where Name ='Commercial1'];
		slot2[0].Commercial__c = commercial1.Id;
		update slot2;
		commercial1 = [Select Id, Broadcasts_Scheduled__c from Commercial__c where Name ='Commercial1'];
		Commercial__c commercial2 = [Select Id, Broadcasts_Scheduled__c from Commercial__c where Name ='Commercial2'];
		System.assertEquals(9, commercial1.Broadcasts_Scheduled__c);
		System.assertEquals(0, commercial2.Broadcasts_Scheduled__c);
	}

	@isTest static void testUpdateOfBroadcastCount() {
		List<Commercial_Slot__c> slot1 = [Select Id, Commercial__c from Commercial_Slot__c where Number_of_Broadcasts__c = 4 and Commercial__r.Name = 'Commercial1'];
		slot1[0].Number_of_Broadcasts__c = 5;
		List<Commercial_Slot__c> slot2 = [Select Id, Commercial__c from Commercial_Slot__c where Number_of_Broadcasts__c = 2 and Commercial__r.Name = 'Commercial2'];
		slot2[0].Number_of_Broadcasts__c = 3;
		List<Commercial_Slot__c> slots = new List<Commercial_Slot__c> {slot1[0], slot2[0]};
		update slots;
		Commercial__c commercial1 = [Select Id, Broadcasts_Scheduled__c from Commercial__c where Name ='Commercial1'];
		Commercial__c commercial2 = [Select Id, Broadcasts_Scheduled__c from Commercial__c where Name ='Commercial2'];
		System.assertEquals(8, commercial1.Broadcasts_Scheduled__c);
		System.assertEquals(3, commercial2.Broadcasts_Scheduled__c);
	}

	@isTest static void testUpdateOfTimeslot() {
		List<Commercial_Slot__c> slot2 = [Select Id, Timeslot__c from Commercial_Slot__c where Number_of_Broadcasts__c = 2 and Commercial__r.Name = 'Commercial2'];
		List<Commercial_Slot__c> slot3 = [Select Id, Timeslot__c from Commercial_Slot__c where Number_of_Broadcasts__c = 3 and Commercial__r.Name = 'Commercial1'];
		List<String> programNames = new List<String>{'Movie Night1','Movie Night2'};
		List<Timeslot__c> timeslots12 = [Select Id, Scheduled_Commercial_Time_Seconds__c from Timeslot__c
			where Program_Name__c in :programNames order by Program_Name__c];

		slot2[0].Timeslot__c = timeslots12[1].id;
		slot3[0].Timeslot__c = timeslots12[0].id;
		List<Commercial_Slot__c> slots = new List<Commercial_Slot__c> {slot2[0], slot3[0]};
		update slots;
		timeslots12 = [Select Id, Scheduled_Commercial_Time_Seconds__c from Timeslot__c
			where Program_Name__c in :programNames order by Program_Name__c];

		System.assertEquals(140, timeslots12[0].Scheduled_Commercial_Time_Seconds__c);
		System.assertEquals(40, timeslots12[1].Scheduled_Commercial_Time_Seconds__c);
	}
}