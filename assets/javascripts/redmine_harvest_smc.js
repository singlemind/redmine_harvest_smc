function redrawTimeout() {
	$('#redmine_harvest_smc_table').dataTable().fnDraw();
}

// function addCommas(nStr){nStr+='';x=nStr.split('.');x1=x[0];x2=x.length>1?'.'+ x[1]:'';var rgx=/(\d+)(\d{3})/;while(rgx.test(x1)){x1=x1.replace(rgx,'$1'+','+'$2');}
// return x1+ x2;}

$(document).ready(function() {
	var oTable = $('#redmine_harvest_smc_table').dataTable( 
		{ //"sScrollY": "400px" 
    //  "bProcessing": true
		  "bPaginate": true
    , "sPaginationType": "full_numbers"
      
    , "bLengthChange": true 
    , "iDisplayLength": 500
    , "aLengthMenu": [[100, 250, 500, 1000, 5000, -1], [100, 250, 500, 1000, 5000, "All"]]
		
    , "bStateSave": true

		, "aaSorting": [[ 1, "desc" ]]
		, "bAutoWidth": true
		, "fnRowCallback": function( nRow, aData, iDisplayIndex ) {
            
            if ( aData[1] == "problem" )
            {
                $('td:eq(1)', nRow).html( '<b title="PROBLEM">PROBLEM</b>' );
                $( 'td:eq(1)', nRow ).addClass("hightlightedRow");
            }
        }

    , "fnFooterCallback": function (nRow, aaData, iStart, iEnd, aiDisplay ) {
        var total_time = 0;
        //var total_costs = 0;
 
        /*Calculate the total for all rows, even outside this page*/
        for (var i = 0; i < aaData.length ; i++) {
            /*Have to strip out extra characters so parsefloat and parseInt work right*/
            total_time += parseFloat(aaData[i][7].replace(/<(?:.|\n)*?>/gm, ''));
            //total_costs += parseFloat(aaData[i][3].replace('$', '').replace(',',''));
         }
        
        var pageTotal_count = 0;
        //var pageTotal_costs = 0;

        /*calculate totals for this page*/
        for (var i = iStart; i < iEnd; i++) {
          //console.log("parseFloat: "+aaData[aiDisplay[i]][7].replace(/<(?:.|\n)*?>/gm, '') );
          pageTotal_count += parseFloat(aaData[aiDisplay[i]][7].replace(/<(?:.|\n)*?>/gm, ''));
          //pageTotal_costs += parseFloat(aaData[aiDisplay[i]][3].replace('$', '').replace(',',''));
        }

        
        Math.ceil(total_time * 100) / 100;
        //console.log(" pageTotal_count: "+ pageTotal_count);
        /*modify the footer row*/
        // var nCells = nRow.getElementsByTagName('thead');
        // console.log(nCells);
        // nCells[1].innerHTML = addCommas(pageTotal_count) +
        //     '(' + addCommas(total_time) + ' total)';
        //console.log( addCommas(pageTotal_count) + '(' + addCommas(total_time) + ' total)' );
        
        $(".rm_smc_hours_total").html( Math.ceil(pageTotal_count * 100) / 100 );
        // nCells[3].innerHTML = '$' + addCommas(pageTotal_costs.toFixed(2)) +
        //     '($' + addCommas(total_costs.toFixed(2)) + ' total)';
    }

    , "aoColumnDefs": 
		[
				{ "sWidth": "55px", "aTargets": [ 0 ] }
			, { "bSortable": false, "aTargets": [ 0 ] }
      , { "bSearchable": false, "aTargets": [ 0 ] } 
      , { "sType": "date", "aTargets": [ 2 ] }
      
    ]
    	//
      /* a bit cryptic; essentially a <"clear"> could go where the space is btwn C lfrtip
       * 'l' - Length changing
       * 'f' - Filtering input
       * 't' - The table!
       * 'i' - Information
       * 'p' - Pagination
       * 'r' - pRocessing
       * The following constants are allowed:
       * 'H' - jQueryUI theme "header" classes ('fg-toolbar ui-widget-header ui-corner-tl ui-corner-tr ui-helper-clearfix')
       * 'F' - jQueryUI theme "footer" classes ('fg-toolbar ui-widget-header ui-corner-bl ui-corner-br ui-helper-clearfix')
       * The following syntax is expected:
       * '<' and '>' - div elements
       * '<"class" and '>' - div with a class
       * '<"#id" and '>' - div with an ID
       * Examples:
       * '<"wrapper"flipt>'
       * 'ip>'
      */
    	//and lfr is the search box... 
    , "sDom": 'C t<"F"lip>'
    //, "sDom": 't<"F"lip>'
		, "oColVis": 
		{
			"aiExclude": [ 0 ]
		}

	} );

	oTable.dataTable().columnFilter({
		//#TODO: refactor this aoColumns to use aoColumnDefs
		aoColumns: 
		[ null 
		, { sSelector: "#statusFilter", type: "checkbox", values: [ 'new', 'problem', 'flagged', 'complete', 'locked' ] }
		, { sSelector: "#rmDateFilter" }
		, { sSelector: "#rmUserFilter", type: "select"  } 
		, { sSelector: "#rmIssueFilter" } 
		, { sSelector: "#projectFilter", type: "select"  }
		, { sSelector: "#taskFilter", type: "select"  } 
		, { sSelector: "#hoursFilter" }
		, { sSelector: "#notesFilter" }

	  ]
	});		


	// loadbang the oTable so that things don't shift around when col sorting or filters are used... 
	//oTable.fnDraw();
	setTimeout(redrawTimeout, 100);
	

	function buildHarvestSelects(customFieldVal, operatorVal) {
    //console.log(customFieldVal, operatorVal);
    //TODO: should this have the classname in it? 
    var harvestIntId = jQuery('#harvest_aggregator div').length +1;
    console.log('harvestIntId: '+harvestIntId);
    
    if ( harvestIntId != 1 ) {
      //operator fields
      var fieldWrapper = jQuery('<div class="fieldwrapper" id="harvest_field' + harvestIntId + '"/>');
      
      var fOperators = jQuery('<select class="fieldtype harvest_fields" id="work_order_harvests'+harvestIntId+'" name="settings[work_order_aggregate_harvest_custom_fields'+harvestIntId+']" />');
      var fOpts = {
        "&" : "&",
        "=" : "="
      };
      jQuery.each(fOpts, function(val, text) {
          fOperators.append( new Option(text,val) );
      });
      fieldWrapper.append(fOperators);
      
      if (operatorVal) { jQuery(fOperators).val(operatorVal).attr("selected","selected") }
      
      var removeButton = jQuery('<input type="button" class="remove" value="X" />');
      removeButton.click(function() {
          jQuery(this).parent().remove();
      });
      fieldWrapper.append(removeButton);
      
      jQuery('#harvest_aggregator').append(fieldWrapper);
      var harvestIntId = harvestIntId + 1;
    } 
    
    // custom fields
    var customFieldWrapper = jQuery('<div class="fieldwrapper" id="harvest_field' + harvestIntId + '"/>');
    
    harvestCustomFields.clone(false).find("*[id]").andSelf().each(function() { 
      jQuery(this).attr('id',function(i,id){ return id+harvestIntId; }); 
      jQuery(this).attr('name',function(i,name){ return 'settings[work_order_harvest_fields'+harvestIntId+']'; }); 
      jQuery(this).attr('class','fieldtype harvest_fields'); 
      if (customFieldVal) { jQuery(this).val(customFieldVal).attr("selected","selected") }
    }).appendTo(customFieldWrapper);

    var customRemoveButton = jQuery('<input type="button" class="remove" value="X" />');
    customRemoveButton.click(function() {
        jQuery(this).parent().remove();
    });
    customFieldWrapper.append(customRemoveButton);
    jQuery('#harvest_aggregator').append(customFieldWrapper);
  }

  jQuery('#harvest_aggregator_add').click(function() {  
    buildHarvestSelects(false, false);
  });
  
  //pack the values into a hidden field on submit that then gets saved into the settings array on the Rails server side
  jQuery("#settings form").submit(function(e) {
    //TODO: error handling? validate?
    console.log("PACKING CHEMICAL FIELDS ON_SUBMIT")
    e.preventDefault();
    var harvest_fields = [];
    jQuery(".harvest_fields").each(function(idx){
      harvest_fields.push(jQuery(this).val());
    });
    var work_order_aggregate_harvest_custom_fields = harvest_fields.join(',');
    
    jQuery('#settings_work_order_aggregate_harvest_custom_fields').attr('value', work_order_aggregate_harvest_custom_fields); 
    //console.log('OUT SETTINGZ: ' + settings_work_order_custom_fields);
    jQuery(this).unbind('submit').submit()
    
  });

	
} );