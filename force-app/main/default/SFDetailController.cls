public with sharing class SFDetailController {
    
    @AuraEnabled
    public static SFDetail initialize(String sobjectId, String fieldsets, String sectionNames){
        Id tempSobjectId = sobjectId;
        Set<String> fields = new Set<String>();
        List<String> fieldSetList = fieldsets.split(';');
        List<String> sectionTitleList = sectionNames.split(';');
        Map<String,List<SFField>> fieldsetVsFields = new Map<String,List<SFField>>();
        Set<String> allFields = new Set<String>();
        Integer columnSize = 2;
        Integer fieldSetIndex = 0;
        for(String fieldSet : fieldsetList){  
            if(!fieldset.contains(',')){
                List<String> fieldsetFields = getFieldSetFields(tempSobjectId.getSobjectType()+'',fieldset);
                List<SFField> sfFields = new List<SFField>(); 
                for(String field : fieldsetFields){
                    SFField theSFField = new SFField();
                    theSFField.field = field;
                    sfFields.add(theSFField);
                }
                fieldsetVsFields.put(fieldSetIndex+'',sfFields);
                allFields.addAll(fieldsetFields);
            }else{
                List<String> fieldList = fieldSet.split(',');    
                List<SFField> sfFields = new List<SFField>();            
                for(String field : fieldList){

                    List<String> fieldAndLabelList = field.trim().split('#');
                    SFField theSFField = new SFField();
                    theSFField.field = fieldAndLabelList[0].trim();                    
                    if( fieldAndLabelList.size()>1 ){
                        theSFField.label = fieldAndLabelList[1].trim();
                    }
                    sfFields.add(theSFField);
                }
                fieldsetVsFields.put(fieldSetIndex+'',sfFields);
            }   

            fieldSetIndex++;                   
        }                
        String query = 'SELECT '+String.join(new List<String>(allFields),',')+' FROM '+ tempSobjectId.getSobjectType() + ' WHERE Id=\''+tempSobjectId+'\' ';
        SObject theSobject = Database.query(query)[0];
        SFDetail theSFDetail = new SFDetail();
        theSFDetail.sfsections = new List<SFDetailController.SFSection>();
        
        for(Integer index = 0;index < fieldSetIndex;index++){
            SFDetailController.SFSection sfSection = new SFDetailController.SFSection();            
            sfSection.title = sectionTitleList[index];
            sfSection.rows  = new List<SFDetailController.Row>();
            List<SFField> fieldList = fieldsetVsFields.get(index+'');
            //Handling two cells in a row
            Integer fieldIndex = 0;
            while(fieldIndex < fieldList.size()){
                SFDetailController.Row theRow = new SFDetailController.Row();
                theRow.dataItems = new List<SFDetailController.DataItem>();
                for(Integer colIndex =0;colIndex < columnSize; colIndex++){
                   if(fieldIndex < fieldList.size()){
                        SFDetailController.DataItem dataItem = getDataItem(theSobject, fieldList[fieldIndex].field,fieldList[fieldIndex].label);
                        theRow.dataItems.add(dataItem);
                        fieldIndex++;
                   } 
                }                
                sfSection.rows.add(theRow);
            }
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

    public class SFField{
        public String field;
        public String label;
        public SFField(){
            field = null;
            label = null;
        }
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
   

    public static DataItem getDataItem(SObject sObjectRecord, String fieldFullPath, String label){

        if(fieldFullPath!=null && fieldFullPath.contains('.')){
            SObject lookupSObject = sObjectRecord.getSObject(fieldFullPath.substring(0,fieldFullPath.indexOfIgnoreCase('.')));
            if(lookupSObject!=null){
                return getDataItem(lookupSObject,fieldFullPath.substring(fieldFullPath.indexOfIgnoreCase('.')+1),label);
            }else {
                return null;
            }
        }
        DescribeFieldResult theDescribeFieldResult = sObjectRecord.getSObjectType().getDescribe().fields.getMap().get(fieldFullPath).getDescribe();
        DataItem theDataItem = new DataItem();
        if( label == null ){
            theDataItem.label        = theDescribeFieldResult.getLabel();
        }else{
            theDataItem.label = label;
        }
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