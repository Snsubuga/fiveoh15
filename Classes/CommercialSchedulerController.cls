public with sharing class CommercialSchedulerController { 

	private final Commercial__c commercial;
	public String pageMode { 
		get {
			return ApexPages.currentPage().getParameters().get('Id');
		} 
		set; 
	}
	public String pageSubtitle { get; set; }
	public Boolean editMode { get; set; }
	public Boolean renderChart { get; set; }
	public Boolean renderMessages { get; set; }
	public String filterId { 
		get;
		set; 
	}
	public List<TimeslotWrapper> timeslots { get; set; }
	public List<Commercial_Slot__c> commercialSlots { get; set; }
	private ApexPages.StandardController controller;

	public Decimal numberOfPages { 
		get {
			Decimal pages = con.getResultSize() / con.getPageSize();
			return Math.floor(pages) + ((Math.mod(con.getResultSize(), con.getPageSize()) > 0) ? 1 : 0);
		}
		set; 
	}
	public ApexPages.StandardSetController con {
        get {
            if(con == null) {
                con = new ApexPages.StandardSetController(Database.getQueryLocator([Select Id, 
												Program_Genre__c,
												Program_Name__c,
												Remaining_Commercial_Time_Seconds__c,
												Timeslot_Date_Time__c
										from Timeslot__c
										where
											Timeslot_Date_Time__c >=:commercial.Broadcast_Start_Date__c
										and
											Timeslot_Date_Time__c <=:commercial.Broadcast_Stop_Date__c
										order by 
											Timeslot_Date_Time__c asc]));
                // sets the number of records in each page set
                con.setPageSize(12);
            }
            return con;
        }
        set;
    }
    

    public CommercialSchedulerController(ApexPages.StandardController controller) {
		if (filterId == null) {
			filterId = 'All';
		}
		this.controller = controller;
		//pageMode = ApexPages.currentPage().getParameters().get('Id');
		if (pageMode != null) {
			editMode = true;
			Commercial__c c2 = (Commercial__c)controller.getRecord();System.debug('c2 Id='+c2.Id);
			this.commercial = [Select Id, Account__c, Broadcasts_Scheduled__c, Name, Broadcast_Start_Date__c,
								Broadcast_Stop_Date__c, Contracted_Broadcast_Time_Seconds__c, Running_Time_Seconds__c,
									Total_Broadcast_Time_Seconds__c 
									From Commercial__c where Id =:c2.id];
			pageSubtitle = commercial.Name;
			if (commercial.Broadcasts_Scheduled__c > 0) {
				renderChart = true;
				renderMessages = false;
			}
			else {
				renderChart = false;
				renderMessages = true;
			}
		}
		else {
		editMode = false;
			this.commercial = new Commercial__c();
			pageSubtitle = 'New Commercial';
		}
    }

	public List<SelectOption> getListViewOptions() {
		
		Schema.DescribeFieldResult fieldResult = Timeslot__c.Program_Genre__c.getDescribe();
		List<Schema.PicklistEntry> genreValues = fieldResult.getPicklistValues();
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('All', 'All'));
		for (Schema.PicklistEntry genreValue : genreValues) {
			options.add(new SelectOption(genreValue.getLabel(), genreValue.getValue()));
		}
		return options;
	}

	public PageReference resetFilter() {
		con = null;
		con.setPageNumber(1);
		return null;
	}

	public Commercial__c getCommercial() {
		return commercial;
	}

	public List<TimeslotWrapper> getTimeslots2() {
		Map<Id, Timeslot__c> timeslotsMap = new Map<Id, Timeslot__c>([Select Id, 
												Program_Genre__c,
												Program_Name__c,
												Remaining_Commercial_Time_Seconds__c,
												Timeslot_Date_Time__c
										from Timeslot__c 
										where Timeslot_Date_Time__c >=: commercial.Broadcast_Start_Date__c
											and  
										Timeslot_Date_Time__c <=: commercial.Broadcast_Stop_Date__c]);



		Map<Id, Commercial_Slot__c> timeslotCommercialSlotsMap = new Map<Id, Commercial_Slot__c>();

		commercialSlots = [Select Id, 
									Number_of_Broadcasts__c,
									Timeslot__c,
									Commercial__c,
									Timeslot__r.Program_Genre__c,
									Timeslot__r.Program_Name__c,
									Timeslot__r.Remaining_Commercial_Time_Seconds__c,
									Timeslot__r.Timeslot_Date_Time__c
							from 
									Commercial_Slot__c 
							where 
									Commercial__c =:commercial.id 
							and 
									Timeslot__c in:timeslotsMap.keySet()];

		timeslots = new List<TimeslotWrapper>();
		for (Commercial_Slot__c cslot : commercialSlots) {
			timeslotCommercialSlotsMap.put(cslot.Timeslot__c, cslot);
			

		}
		List<Timeslot__c> tslots = (List<Timeslot__c>)con.getRecords();
		tslots = returnFilteredSlots(tslots);
		//con = new ApexPages.StandardSetController(tslots);con.setPageSize(12);
		
		//for (Timeslot__c timeslot: (List<Timeslot__c>)con.getRecords()) {
		for (Timeslot__c timeslot: tslots) {
			
			if (timeslotCommercialSlotsMap.get(timeslot.Id) == null) {
				timeslots.add(new TimeslotWrapper(timeslot, 0, this));
				Commercial_Slot__c slot = new Commercial_Slot__c();
				slot.Number_of_Broadcasts__c = 0;
				slot.Timeslot__c = timeslot.Id;
				slot.Commercial__c = commercial.Id;
				slot.Date_Time__c = timeslot.Timeslot_Date_Time__c;
				timeslotCommercialSlotsMap.put(slot.Timeslot__c, slot);
			}
			else {
				timeslots.add(new TimeslotWrapper(timeslot, timeslotCommercialSlotsMap.get(timeslot.Id).Number_of_Broadcasts__c, this));
			}
		}
		System.debug('timeslots size ='+timeslots.size());
		return timeslots;
	}
	public List<BarGraphBroadcastData> getBroadcastData() {
		if (pageMode != null) {
			System.debug('we are in bizNess :'+pageMode); 
			// Create the x-axis which has all dates between commercial start and end date
			List<Date> broadcastDates = getEligibleCommercialDates(commercial);
			List<BarGraphBroadcastData> graphData = new List<BarGraphBroadcastData>();
			for (Date broadcastDate : broadcastDates) {
				graphData.add(new BarGraphBroadcastData(broadcastDate.format(), 0));
			}

			
			List<Commercial_Slot__c> commercialSlots = [Select Id, 
																Name, 
																Total_Broadcast_Time_Seconds_c__c, 
																Date_Time__c,
																Timeslot__r.Program_Genre__c,
																Timeslot__r.Timeslot_Date_Time__c
														from 
															Commercial_Slot__c 
														where 
															Commercial__c =:commercial.Id];

			// Create a list/map of dates and commercial slots
			Map<String, List<Commercial_Slot__c>> dateSlots = new Map<String, List<Commercial_Slot__c>>();

			commercialSlots = returnFilteredCommercialSlots(commercialSlots);
			if (!commercialSlots.isEmpty()) {
				for (Commercial_Slot__c slot : commercialSlots) {
					
					Date commercialDate = slot.Timeslot__r.Timeslot_Date_Time__c.date();
					if (dateSlots.get(commercialDate.format()) == null) {
						List<Commercial_Slot__c> slots = new List<Commercial_Slot__c>{slot};
						dateSlots.put(commercialDate.format(), slots);
					}
					else {
						List<Commercial_Slot__c> slots = dateSlots.get(commercialDate.format());
						slots.add(slot);
						dateSlots.put(commercialDate.format(), slots);
					}
				}
				//renderChart = true;
			}
			else {
				//renderChart = false;
			}
			for (BarGraphBroadcastData graphDatam: graphData) {
				String commercialDate = graphDatam.name;
				if (dateSlots.get(commercialDate) != null) {
					List<Commercial_Slot__c> slots = dateSlots.get(commercialDate);
					graphDatam.data = getTotalBroadcastTimeInSeconds(slots);
				}
			}
			return graphData;
		}
		return null;
	}
	private List<Date> getEligibleCommercialDates(Commercial__c commercial) {
		List<Date> dates = new List<Date>();System.debug('dates='+commercial.Broadcast_Start_Date__c + ' and '+commercial.Broadcast_Stop_Date__c);
		dates.add(commercial.Broadcast_Start_Date__c);
		Integer daysBetweenBroadcastDates = commercial.Broadcast_Start_Date__c.daysBetween(commercial.Broadcast_Stop_Date__c);
		for (Integer index = 1; index < daysBetweenBroadcastDates; index++) {
			dates.add(commercial.Broadcast_Start_Date__c.addDays(index));
		}
		return dates;
	}

	private Decimal getTotalBroadcastTimeInSeconds(List<Commercial_Slot__c> cslots) {
		Decimal totalBroadcastTime = 0;
		for (Commercial_Slot__c cslot : cslots) {
			totalBroadcastTime+= cslot.Total_Broadcast_Time_Seconds_c__c;
		}
		return totalBroadcastTime;
	}

	public PageReference save() {
		if (editMode) {
			update commercial;
			List<Commercial_Slot__c> commercialSlotsToCreateOrUpdate = new List<Commercial_Slot__c>();
			List<Commercial_Slot__c> commercialSlotsToDelete = new List<Commercial_Slot__c>();
			for (TimeslotWrapper twrapper : timeslots) {
				Commercial_Slot__c cslot = twrapper.save();
				if (cslot != null) {
					if (twrapper.numberOfBroadcasts == 0) {
						commercialSlotsToDelete.add(cslot);
					}
					else {
						commercialSlotsToCreateOrUpdate.add(cslot);
					}
				}
				else {
					if (twrapper.numberOfBroadcasts > 0) {
						cslot = new Commercial_Slot__c();
						cslot.Timeslot__c = twrapper.timeslot.Id;
						cslot.Commercial__c = commercial.Id;
						cslot.Number_of_Broadcasts__c = twrapper.numberOfBroadcasts;
						cslot.Date_Time__c = twrapper.timeslot.Timeslot_Date_Time__c;
						commercialSlotsToCreateOrUpdate.add(cslot);
					}
				}
			}
			if (commercialSlotsToDelete.size() > 0) {
				delete commercialSlotsToDelete;
			}
			if (commercialSlotsToCreateOrUpdate.size() > 0) {System.debug('upserting '+commercialSlotsToCreateOrUpdate.size() + ' records');
				upsert commercialSlotsToCreateOrUpdate;
			}

			return controller.view();
		}
		else {
			insert commercial;
			PageReference commercialDetailPage = new ApexPages.StandardController(commercial).view();
			commercialDetailPage.setRedirect(true);
			return commercialDetailPage;
		}
	}

	public PageReference cancel() {
		PageReference previousPage = new PageReference(ApexPages.currentPage().getParameters().get('retURL'));
		return previousPage; 
	}

	// indicates whether there are more records after the current page set.
    public Boolean hasNext {
        get {
            return con.getHasNext();
        }
        set;
    }

    // indicates whether there are more records before the current page set.
    public Boolean hasPrevious {
        get {
            return con.getHasPrevious();
        }
        set;
    }

    // returns the page number of the current page set
    public Integer pageNumber {
        get {
            return con.getPageNumber();
        }
        set;
    }

    // returns the first page of records
     public void first() {
         con.first();
     }

	// returns the last page of records
	public void last() {
		con.last();
	}

	// returns the previous page of records
	public void previous() {
		con.previous();
	}

	// returns the next page of records
	public void next() {
		con.next();
	}

	private List<Timeslot__c> returnFilteredSlots(List<Timeslot__c> timeslots) {
		System.debug('filtered records call, filterId = '+filterId);
		if (filterId == 'All') {
			return timeslots;
		}
		else {
			List<Timeslot__c> tslots = new List<Timeslot__c>();
			for (Timeslot__c tslot : timeslots) {
				if (tslot.Program_Genre__c == filterId) {
					tslots.add(tslot);
				}
			}
			return tslots;
		}
	}

	private List<Commercial_Slot__c> returnFilteredCommercialSlots(List<Commercial_Slot__c> cslots) {
		List<Commercial_Slot__c> filteredCommercialSlots = new List<Commercial_Slot__c>();
		if (filterId == 'All') {
			filteredCommercialSlots = cslots;
		}
		else {
			for (Commercial_Slot__c cslot : cslots) {
				if (cslot.Timeslot__r.Program_Genre__c == filterId) {
					filteredCommercialSlots.add(cslot);
				}
			}
		}
		if (filteredCommercialSlots.size() > 0) {
			renderChart = true;
			renderMessages = false;
		}
		else {
			renderChart = false;
			renderMessages = true;
		}
		return filteredCommercialSlots;
	}

	public class BarGraphBroadcastData {
		public String name { get; set;}
		public Decimal data { get;	set;}

		public BarGraphBroadcastData(String name, Decimal data) {
			this.name = name;
			this.data = data;
		}
	}

	public class TimeslotWrapper {
		public Timeslot__c timeslot { get; set;}
		public Decimal numberOfBroadcasts { get; set;}
		CommercialSchedulerController csc;

		public TimeslotWrapper(Timeslot__c tslot, Decimal numOfBroadcasts, CommercialSchedulerController con) {
			timeslot = tslot;
			numberOfBroadcasts = numOfBroadcasts;
			this.csc = con;
		}

		public Commercial_Slot__c save() {
			Commercial_Slot__c cslot = null;
			for (Commercial_Slot__c commercialSlot : csc.commercialSlots) {
				if ((commercialSlot.Timeslot__c == timeslot.Id) && (commercialSlot.Commercial__c == csc.commercial.Id)) {
					cslot = commercialSlot;
					cslot.Number_of_Broadcasts__c = numberOfBroadcasts;
					break;
				}
			}
			return cslot;
		}
	}
}