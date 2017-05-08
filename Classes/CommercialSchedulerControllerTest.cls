@isTest
private class CommercialSchedulerControllerTest { 


	@testSetup static void setup() {

		// Create Users
		List<Profile> userProfiles = [SELECT Id FROM Profile WHERE Name in ('Broadcast Planner', 'Network Executive') 
			order by Name asc];
		
		List<User> users = new List<User>();
		for (Integer index = 0; index < 2; index++) {
			User u = new User(Alias = 'user'+index, Email='user'+index+'@testuser.org', 
			EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
			LocaleSidKey='en_US', ProfileId = userProfiles[index].Id, 
			TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com'+index);
			users.add(u);
		} 
		insert users;

		// Create an account
		Account testAccount = new Account(Name='Test Account');
		testAccount.OwnerId = users[0].Id;
		insert testAccount;

		// Create a Commercial
		Commercial__c commercial = new Commercial__c();
		commercial.Name = 'Commercial0';
		commercial.Account__c = testAccount.Id;
		commercial.Broadcast_Start_Date__c = Date.today();
		commercial.Broadcast_Stop_Date__c = Date.today().addDays(14);
		commercial.Contracted_Broadcast_Time_Seconds__c = 2000;
		commercial.Running_Time_Seconds__c = 20;
		commercial.Broadcasts_Scheduled__c = 0;
		commercial.OwnerId = users[0].Id;
		insert commercial;

		// Create Timeslots
		List<Timeslot__c> timeSlots = new List<Timeslot__c>();
		for (Integer index = 0; index < 24; index++) {
			Timeslot__c timeSlot = new Timeslot__c();
			timeSlot.OwnerId = users[0].Id;
			timeSlot.Allowed_Commercial_Time_Seconds__c = 600;
			timeSlot.Program_Name__c = 'Program'+index;
			if (Math.mod(index, 3) == 0) {
				
				timeSlot.Program_Genre__c = 'News';
			}
			else if (Math.mod(index, 5) == 0) {
				timeSlot.Program_Genre__c = 'Sports';
			}
			else {
				timeSlot.Program_Genre__c = 'Family';
			}
			timeSlot.Timeslot_Date_Time__c = Datetime.now().addHours(index);
			timeSlot.Scheduled_Commercial_Time_Seconds__c = 0;
			timeSlots.add(timeSlot);
		}
		insert timeSlots;

		// Create Commercial Slots
		List<Commercial_Slot__c> commercialSlots = new List<Commercial_Slot__c>();
		for (Integer index = 0; index < 24; index++) {
			Commercial_Slot__c commercialSlot = new Commercial_Slot__c();
			commercialSlot.Commercial__c = commercial.Id;
			commercialSlot.Timeslot__c = timeSlots[index].Id;
			commercialSlot.Date_Time__c = timeSlots[index].Timeslot_Date_Time__c;
			commercialSlot.Number_of_Broadcasts__c = Math.mod(24, (index+1));
			commercialSlots.add(commercialSlot);
		}
		insert commercialSlots;
	}
	@isTest static void testControllerWithAuthorizedUser() {



		Test.startTest();
		List<String> usernames = new List<String>(); 
		usernames.add('standarduser@testorg.com0');usernames.add('standarduser@testorg.com1');
		List<User> users = [Select Id from User where UserName in :usernames order by UserName asc];

		// retrieve previously created Commercial
		List<Commercial__c> commercial = [Select Id from Commercial__c where Name = 'Commercial0'];
		System.runAs(users[0]) {
			PageReference pageRef = Page.CommercialScheduler;
			pageRef.getParameters().put('Id', commercial[0].Id);
			Test.setCurrentPage(pageRef);

			ApexPages.StandardController sc = new ApexPages.standardController(commercial[0]);
			CommercialSchedulerController csc = new CommercialSchedulerController(sc);
			

			System.assertEquals('All', csc.filterId);

			System.assertEquals(10, csc.getListViewOptions().size());

			System.assertEquals(12, csc.getTimeslots2().size());

			System.assertEquals(12, csc.con.getPageSize());

			System.assertEquals(24, csc.con.getResultSize());

			System.assertEquals(true, csc.hasNext);
			System.debug('pagemode = '+ApexPages.currentPage().getParameters().get('Id'));

			System.assertEquals(14, csc.getBroadcastData().size());

			System.assertEquals(2, csc.numberOfPages);
			csc.first();
			System.assertEquals(1, csc.con.getPageNumber());
			System.assertEquals(1, csc.pageNumber);
			System.assertEquals(true, csc.hasNext);

			csc.last();
			System.assertEquals(2, csc.con.getPageNumber());

			csc.previous();
			System.assertEquals(1, csc.con.getPageNumber());

			csc.next();
			System.assertEquals(2, csc.con.getPageNumber());

			System.assertEquals(true, csc.hasPrevious);

			csc.resetFilter();
			System.assertEquals(1, csc.con.getPageNumber());

			System.debug('editable timeslots ='+csc.timeslots.size());
			List<CommercialSchedulerController.TimeslotWrapper> wrappersToUpdate = new List<CommercialSchedulerController.TimeslotWrapper>();
			for (CommercialSchedulerController.TimeslotWrapper twrapper : csc.timeslots) {
				twrapper.numberOfBroadcasts = 5;
				wrappersToUpdate.add(twrapper);
			}
			csc.timeslots = wrappersToUpdate;
			csc.save();
			List<Commercial_Slot__c> cslots = [Select Number_of_Broadcasts__c from Commercial_Slot__c where Commercial__c =:commercial[0].Id limit 12];
			for (Commercial_Slot__c cslot : cslots) {
				System.assertEquals(5, cslot.Number_of_Broadcasts__c);
			}

		}
		
		Test.stopTest();
	}

	/**
	* using a Network Executive User 
	*/
	@isTest static void testControllerWithUnauthorizedUser() {

		Test.startTest();
		List<User> unauthorizedUser = [Select Id from User where UserName = 'standarduser@testorg.com1'];

		System.runAs(unauthorizedUser[0]) {
			// retrieve previously created Commercial
			List<Commercial__c> commercial = [Select Id from Commercial__c where Name = 'Commercial0'];

			System.assertEquals(0, commercial.size());
		}
		Test.stopTest();
	}

	/**
	* tests exexcution of the page when the filter is not
	* set to the 'All' value
	*/
	@isTest static void testWithNonAllFilter() {

		Test.startTest();
		List<String> usernames = new List<String>(); 
		usernames.add('standarduser@testorg.com0');usernames.add('standarduser@testorg.com1');
		List<User> users = [Select Id from User where UserName in :usernames order by UserName asc];

		// retrieve previously created Commercial
		List<Commercial__c> commercial = [Select Id from Commercial__c where Name = 'Commercial0'];
		System.runAs(users[0]) {
			PageReference pageRef = Page.CommercialScheduler;
			pageRef.getParameters().put('Id', commercial[0].Id);
			Test.setCurrentPage(pageRef);

			ApexPages.StandardController sc = new ApexPages.standardController(commercial[0]);
			CommercialSchedulerController csc = new CommercialSchedulerController(sc);
			
			csc.filterId = 'Sports';
			System.assertEquals('Sports', csc.filterId);

			System.assertEquals(2, csc.getTimeslots2().size());
			System.assertEquals(14, csc.getBroadcastData().size());
			Test.stopTest();
		}
	}

	@isTest static void testCancelButton() {

		List<Commercial__c> commercial = [Select Id from Commercial__c where Name = 'Commercial0'];

		PageReference commercialDetailPage = new ApexPages.StandardController(commercial[0]).view();
		Test.setCurrentPage(commercialDetailPage);

		PageReference pageRef = Page.CommercialScheduler;
		
		pageRef.getParameters().put('Id', commercial[0].Id);
		pageRef.getParameters().put('retURL', commercialDetailPage.getUrl());
		Test.setCurrentPage(pageRef);

		ApexPages.StandardController sc = new ApexPages.standardController(commercial[0]);
		CommercialSchedulerController csc = new CommercialSchedulerController(sc);

		PageReference previousPage = csc.cancel();
		System.assertNotEquals(previousPage, pageRef);
	}
}