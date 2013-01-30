/**
 * @author edward
 */


  

  $(document).ready(function() {
  	var lastChecked = null;
	  var $chkboxen = $('.chkbx_shft_lstnr');
	  $chkboxen.click(function(event) {
	    if(!lastChecked) {
	      lastChecked = this;
	      return;
	    }
	
	    if(event.shiftKey) {
        var start = $chkboxen.index(this);
        var end = $chkboxen.index(lastChecked);

        $chkboxen.slice(Math.min(start,end), Math.max(start,end)+ 1).attr('checked', lastChecked.checked);
	    }

	    lastChecked = this;
	  });
	  
	  
	  $('#rm_smc_checkall').click(function () {
			$(this).parents('form').find(':checkbox').attr('checked', this.checked);
		});

  });
      

