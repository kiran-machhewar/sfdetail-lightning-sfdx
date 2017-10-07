public with sharing class SFDetailController {
    
    @AuraEnabled
    public static SFDetail initialize(String sobjectId, String fieldsets, String sectionNames){
        Id tempSobjectId = sobjectId;
        Set<String> fields = new Set<String>();
        List<String> fieldSetList = fieldsets.split(';');
        List<String> sectionTitleList = sectionNames.split(';');
        Map<String,List<String>> fieldsetVsFields = new Map<String,List<String>>();
        Set<String> allFields = new Set<String>();
        for(String fieldSet : fieldsetList){
            List<String> fieldsetFields = getFieldSetFields(tempSobjectId.getSobjectType()+'',fieldset);
            fieldsetVsFields.put(fieldset,fieldsetFields);
            allFields.addAll(fieldsetFields);
        }                
        String query = 'SELECT '+String.join(new List<String>(allFields),',')+' FROM '+ tempSobjectId.getSobjectType() + ' WHERE Id=\''+tempSobjectId+'\' ';
        SObject theSobject = Database.query(query)[0];
        SFDetail theSFDetail = new SFDetail();
        theSFDetail.sfsections = new List<SFDetailController.SFSection>();
        Integer index = 0;
        for(String fieldset : fieldSetList){
            SFDetailController.SFSection sfSection = new SFDetailController.SFSection();            
            sfSection.title = sectionTitleList[index];
            sfSection.rows  = new List<SFDetailController.Row>();
            List<String> fieldList = fieldsetVsFields.get(fieldset);
            //Handling two cells in a row
            Integer fieldIndex = 0;
            while(fieldIndex < fieldList.size()){
                SFDetailController.Row theRow = new SFDetailController.Row();
                theRow.dataItems = new List<SFDetailController.DataItem>();
                //data item 1
                SFDetailController.DataItem dataItem1 = getDataItem(theSobject, fieldList[fieldIndex]);
                theRow.dataItems.add(dataItem1);
                fieldIndex++;

                //data item 2
                if(fieldIndex < fieldList.size()){
                    SFDetailController.DataItem dataItem2 = getDataItem(theSobject, fieldList[fieldIndex]);
                    theRow.dataItems.add(dataItem2);
                    fieldIndex++;
                }
                sfSection.rows.add(theRow);
            }
            index++;
            theSFDetail.sfsections.add(sfSection);
        }

        return theSFDetail;
    }
    
    
    public class SFDetail{
        @AuraEnabled
        public List<SFSection> sfsections = new List<SFSection>();
    }
    
    public class SFSection{
        @AuraEnabled
        public String title;
        @AuraEnabled
        public List<Row> rows = new List<Row>();
    }
    
    public class Row{
        @AuraEnabled
        public List<DataItem> dataItems = new List<DataItem>();
    }
    
    public class DataItem{
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
        @AuraEnabled
        public String dataType;
        public DataItem(String label,String value, String dataType){
            this.label 		= label;
            this.value 		= value;
            this.dataType 	= dataType;
        }
        public DataItem(){}
    }

    public static List<String> getFieldSetFields(String objectName,String fieldSetName){
	  	  List<String> fieldList = new List<String>();
	  	  Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
	      Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(objectName);
	      Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();            
	      Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);               	  
	      if(fieldSetName!=null && objectName!=null){
	        //To avoid duplicate entries using set to add elements	        
	        for(Schema.FieldSetMember member : fieldSetObj.getFields()){
	            fieldList.add(member.fieldPath.toLowerCase());
	        }   
	      }     
	      return fieldList;  
	}
   

    public static DataItem getDataItem(SObject sObjectRecord, String fieldFullPath){

        if(fieldFullPath!=null && fieldFullPath.contains('.')){
            SObject lookupSObject = sObjectRecord.getSObject(fieldFullPath.substring(0,fieldFullPath.indexOfIgnoreCase('.')));
            if(lookupSObject!=null){
                return getDataItem(lookupSObject,fieldFullPath.substring(fieldFullPath.indexOfIgnoreCase('.')+1));
            }else {
                return null;
            }
        }
        DescribeFieldResult theDescribeFieldResult = sObjectRecord.getSObjectType().getDescribe().fields.getMap().get(fieldFullPath).getDescribe();
        DataItem theDataItem = new DataItem();
        theDataItem.label        = theDescribeFieldResult.getLabel();
        theDataItem.dataType     = theDescribeFieldResult.getType()+'';

        if(sObjectRecord.get(fieldFullPath) instanceof Date && sObjectRecord.get(fieldFullPath) !=null ){
            theDataItem.value = ((Date)sObjectRecord.get(fieldFullPath)).format();
        }else if(sObjectRecord.get(fieldFullPath) instanceof DateTime && sObjectRecord.get(fieldFullPath) !=null ){
            theDataItem.value = ((DateTime)sObjectRecord.get(fieldFullPath)).format();
        }else {
            theDataItem.value = ''+(( sObjectRecord.get(fieldFullPath) == null )?'':sObjectRecord.get(fieldFullPath));
        }
        return theDataItem;
    }
}