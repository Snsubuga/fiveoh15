public class SampleClass {
	public  List<SelectOption> options { 
	get {
		ApexPages.StandardSetController con = new ApexPages.StandardSetController(Database.getQueryLocator([Select Id, 
												Program_Genre__c,
												Program_Name__c,
												Remaining_Commercial_Time_Seconds__c,
												Timeslot_Date_Time__c
										from Timeslot__c]));
		return con.getListViewOptions();
	} 
	set; 
	}
}