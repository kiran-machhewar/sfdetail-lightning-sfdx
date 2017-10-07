({
    doInit : function(component, event, helper) {
		// Create the action
        var action = component.get("c.initialize");
		action.setParams({
            sobjectId           : component.get("v.sobjectId"),
            fieldsets           : component.get("v.fieldsets"),
			sectionNames        : component.get("v.sectionNames"),
			columnSizeStr		: ''+component.get("v.columnSize")           
		});
		component.set("v.showSpinner","true");
		// Add callback behavior for when response is received

		var toastEvent = $A.get("e.force:showToast");
		action.setCallback(this, function(response) {
		    component.set("v.showSpinner","false");
		    var state = response.getState();  
		    if (component.isValid() && state === "SUCCESS" ) {
                var result = response.getReturnValue();
                component.set("v.data",result);
                console.log(result);							
		    }
		    else {
				console.log("Failed with state: " + state);
				console.log("response",response);	
				toastEvent.setParams({
					"title": "Error!",
					"type": "error",
					"message": "Error "+response.getError()[0].message
				});	
				toastEvent.fire();
            }            
		    
		});
		// Send action off to be executed
		$A.enqueueAction(action);
	}
})