var followup=0;

$(document).ready(function() {
    showhide();
    $("#continue").click(function() {
        $.ajax({
        url : '/finalize_userroles',
        type: "POST",
        data : $('#spreadsheetfinalize').serialize(),
        success: function(data){
            $('#spreadsheet_finalize_items').html(data);
        },
        complete: function() {
            showhide();
        }
      });
    });
    $("#cancel").click(function() {
        $.ajax({
        url : '/finalize_userroles',
        type: "POST",
        data : {cancel:1},
        success: function(data){
            $('#spreadsheet_finalize_items').html(data);
        },
        complete: function() {
            followup=0;
            showhide();
         }
      });
    });
    $("#skip").click(function() {
        $.ajax({
        url : '/finalize_userroles',
        type: "POST",
        data : $('#spreadsheetfinalize').serialize()+"&skip=1",
        success: function(data){
            $('#spreadsheet_finalize_items').html(data);
        },
        complete: function() {
            showhide();
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
