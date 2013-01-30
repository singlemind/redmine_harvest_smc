function redrawTimeout() {
	$('#redmine_harvest_smc_table').dataTable().fnDraw();
}

function restoreRow ( oTable, nRow )
{
	var aData = oTable.fnGetData(nRow);
	var jqTds = $('>td', nRow);
	
	for ( var i=0, iLen=jqTds.length ; i<iLen ; i++ ) {
		//oTable.fnUpdate( aData[i], nRow, i, false );
	}
	
	oTable.fnDraw();
}

function editRow ( oTable, nRow )
{
	var aData = oTable.fnGetData(nRow);
	var jqTds = $('>td', nRow);
	//jqTds[0].innerHTML = '<input type="text" value="'+aData[0]+'">';

}

function saveRow ( oTable, nRow )
{
	var jqInputs = $('input', nRow);

	oTable.fnDraw();
}

$(document).ready(function() {
	var oTable = $('#redmine_harvest_smc_table').dataTable( 
		{ "sScrollY": "400px"
		, "bPaginate": false
		, "bStateSave": true

		, "aaSorting": [[ 3, "desc" ]]
		, "bAutoWidth": true
		, "aoColumnDefs": 
		[
				{ "sWidth": "55px", "aTargets": [ 0, 1 ] }
			, { "bSortable": false, "aTargets": [ 0, 1 ] }
      , { "bSearchable": false, "aTargets": [ 0, 1 ] } 
      , { "sType": "date", "aTargets": [ 3 ] }
      
    ]
    	//a bit cryptic; essentially a <"clear"> could go where the space is btwn C lfrtip
    , "sDom": 'C lfrtip'
		, "oColVis": 
		{
			"aiExclude": [ 0 ]
		}

	} );

	oTable.dataTable().columnFilter({
		//#TODO: refactor this aoColumns to use aoColumnDefs
		aoColumns: 
		[ null 
		,	null 
		, { sSelector: "#statusFilter", type: "checkbox", values: [ 'new', 'problem', 'unmatched', 'flagged', 'complete', 'locked' ] }
		, { sSelector: "#rmDateFilter" }
		, { sSelector: "#rmUserFilter", type: "select"  } 
		, { sSelector: "#rmIssueFilter" } 
		, { sSelector: "#clientFilter", type: "select"  }
		, { sSelector: "#taskFilter", type: "select"  } 
		, { sSelector: "#hoursFilter" }
		, { sSelector: "#notesFilter" }

	  ]
	});		



	// loadbang the oTable so that things don't shift around when col sorting or filters are used... 
	//oTable.fnDraw();
	setTimeout(redrawTimeout, 100);

	$('#rm_smc_reset_filterz').click( function(e){
		
		$.cookie('SpryMedia_DataTables_redmine_harvest_smc_table_harvest', null, { path: '/' });
		//$.removeCookie("SpryMedia_DataTables_redmine_harvest_smc_table_");
	
	});

	// $('#rm_smc_fetch_today').click( function(e){
	// 	e.preventDefault();
	// 	$.ajax(
	// 	  { url: $(this).attr('href')
	// 	  , cache: false
	// 		}
	// 	).done(function( html ) 
	// 		{ //$("#results").append(html); 
	// 			redrawTimeout();
	// 			console.log("DONE");
	// 		}
	// 	);
		
	// });

	var nEditing = null;

	$('#rm_harvest_smc_new').click( function (e) {
		e.preventDefault();
		
		//var aiNew = oTable.fnAddData( [ '', '', '', '', '', 
		//	'<a class="rm_harvest_smc_edit" href="">edit</a>', '<a class="rm_harvest_smc_delete" href="">delete</a>' ] );
		//var nRow = oTable.fnGetNodes( aiNew[0] );
		//editRow( oTable, nRow );
		nEditing = nRow;
	} );
	
	$('#redmine_harvest_smc_table a.rm_harvest_smc_delete').on('click', function (e) {
		e.preventDefault();
		console.log("CLICK00");
		var nRow = $(this).parents('tr')[0];
		//console.log( "NROW: "+nRow );
		//oTable.fnDeleteRow( nRow );
	} );
	
	$('#redmine_harvest_smc_table a.rm_harvest_smc_edit').on('click', function (e) {
		e.preventDefault();
		console.log("CLICK01");
		/* Get the row as a parent of the link that was clicked on */
		var nRow = $(this).parents('tr')[0];
		
		if ( nEditing !== null && nEditing != nRow ) {
			/* Currently editing - but not this row - restore the old before continuing to edit mode */
			//restoreRow( oTable, nEditing );
			//editRow( oTable, nRow );
			nEditing = nRow;
		}
		else if ( nEditing == nRow && this.innerHTML == "save" ) {
			/* Editing this row and want to save it */
			saveRow( oTable, nEditing );
			nEditing = null;	
		}
		else {
			/* No edit in progress - let's start one */
			editRow( oTable, nRow );
			nEditing = nRow;
		}
	} );
} );