var followup=0;
var require='';

$(document).ready(function() {
    showhide();
    $("#continue").click(function() {
        $.ajax({
        url : '/finalize_userroles',
        type: "POST",
        data : $('#spreadsheetfinalize').serialize(),
        beforeSend: function() {
           var checkon=require.split(',');
           for (var i=0; i<checkon.length; i++) {
              if ($('#'+checkon[i]).val()=='') {
                 $('.lcerror').show();
                 return false;
              }
           }
           $('.lcerror').hide();
           return true;
        },
        success: function(data){
            $('#spreadsheet_finalize_items').html(data);
        },
        complete: function() {
            showhide();
            adjust_framesize();
        }
      });
    });
    $("#cancel").click(function() {
        $.ajax({
        url : '/finalize_userroles',
        type: "POST",
        data : {cancel:1},
        success: function(data){
            $('.lcerror').hide();
            $('#spreadsheet_finalize_items').html(data);
        },
        complete: function() {
            followup=0;
            showhide();
            adjust_framesize();
         }
      });
    });
    $("#skip").click(function() {
        $.ajax({
        url : '/finalize_userroles',
        type: "POST",
        data : $('#spreadsheetfinalize').serialize()+"&skip=1",
        success: function(data){
            $('.lcerror').hide();
            $('#spreadsheet_finalize_items').html(data);
        },
        complete: function() {
            showhide();
            adjust_framesize();
        }
      });
    });
});

function showhide() {
   if (followup==1) {
      $('.lcproblem').show();
      $('.lcsuccess').hide();
   } else {
      $('.lcproblem').hide();
      $('.lcsuccess').show();
   }
}
