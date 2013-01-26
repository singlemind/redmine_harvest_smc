function restoreRow ( oTable, nRow )
{
	var aData = oTable.fnGetData(nRow);
	var jqTds = $('>td', nRow);
	
	for ( var i=0, iLen=jqTds.length ; i<iLen ; i++ ) {
		oTable.fnUpdate( aData[i], nRow, i, false );
	}
	
	oTable.fnDraw();
}

function editRow ( oTable, nRow )
{
	var aData = oTable.fnGetData(nRow);
	var jqTds = $('>td', nRow);
	//jqTds[0].innerHTML = '<input type="text" value="'+aData[0]+'">';
	jqTds[1].innerHTML = '<input type="text" value="'+aData[1]+'">';
	jqTds[2].innerHTML = '<input type="text" value="'+aData[2]+'">';
	jqTds[3].innerHTML = '<input type="text" value="'+aData[3]+'">';
	jqTds[4].innerHTML = '<input type="text" value="'+aData[4]+'">';
	jqTds[5].innerHTML = '<input type="text" value="'+aData[5]+'">';
	jqTds[6].innerHTML = '<input type="text" value="'+aData[6]+'">';
	jqTds[7].innerHTML = '<input type="text" value="'+aData[7]+'">';
	jqTds[8].innerHTML = '<input type="text" value="'+aData[8]+'">';
	jqTds[9].innerHTML = '<input type="text" value="'+aData[9]+'">';
	jqTds[10].innerHTML = '<input type="text" value="'+aData[10]+'">';
	jqTds[11].innerHTML = '<a class="rm_harvest_smc_edit" href="">save</a>';
}

function saveRow ( oTable, nRow )
{
	var jqInputs = $('input', nRow);
	//oTable.fnUpdate( jqInputs[0].value, nRow, 0, false );
	oTable.fnUpdate( jqInputs[1].value, nRow, 1, false );
	oTable.fnUpdate( jqInputs[2].value, nRow, 2, false );
	oTable.fnUpdate( jqInputs[3].value, nRow, 3, false );
	oTable.fnUpdate( jqInputs[4].value, nRow, 4, false );
	oTable.fnUpdate( jqInputs[4].value, nRow, 5, false );
	oTable.fnUpdate( jqInputs[4].value, nRow, 6, false );
	oTable.fnUpdate( jqInputs[4].value, nRow, 7, false );
	oTable.fnUpdate( jqInputs[4].value, nRow, 8, false );
	oTable.fnUpdate( jqInputs[4].value, nRow, 9, false );
	oTable.fnUpdate( jqInputs[4].value, nRow, 10, false );
	oTable.fnUpdate( '<a class="rm_harvest_smc_edit" href="">Edit</a>', nRow, 11, false );
	oTable.fnDraw();
}

$(document).ready(function() {
	var oTable = $('#redmine_harvest_smc_table').dataTable( {
		"sScrollY": "400px",
		"bPaginate": false,

		"aoColumns": [
			{ "bSortable": false },
			null,
			null,
			null,
			null,
			null,
			null,
			{ "bSortable": false },
			{ "bSortable": false }
		],
		"aaSorting": [[ 2, "desc" ]]
	} );
	var nEditing = null;
	
	$('#rm_harvest_smc_new').click( function (e) {
		e.preventDefault();
		
		var aiNew = oTable.fnAddData( [ '', '', '', '', '', 
			'<a class="rm_harvest_smc_edit" href="">edit</a>', '<a class="rm_harvest_smc_delete" href="">delete</a>' ] );
		var nRow = oTable.fnGetNodes( aiNew[0] );
		editRow( oTable, nRow );
		nEditing = nRow;
	} );
	
	$('#redmine_harvest_smc_table a.rm_harvest_smc_delete').on('click', function (e) {
		e.preventDefault();
		
		var nRow = $(this).parents('tr')[0];
		oTable.fnDeleteRow( nRow );
	} );
	
	$('#redmine_harvest_smc_table a.rm_harvest_smc_edit').on('click', function (e) {
		e.preventDefault();
		
		/* Get the row as a parent of the link that was clicked on */
		var nRow = $(this).parents('tr')[0];
		
		if ( nEditing !== null && nEditing != nRow ) {
			/* Currently editing - but not this row - restore the old before continuing to edit mode */
			restoreRow( oTable, nEditing );
			editRow( oTable, nRow );
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