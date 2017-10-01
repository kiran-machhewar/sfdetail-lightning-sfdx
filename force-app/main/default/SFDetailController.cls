public with sharing class SFDetailController {
    
    @AuraEnabled
    public static SFDetail initialize(String sobjectId, String fieldsets, String sectionNames){
        Id tempSobjectId = sobjectId;
        Set<String> fields = new Set<String>();
        
        
        return null;
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
    }
}