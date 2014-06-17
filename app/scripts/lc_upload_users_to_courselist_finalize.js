$(document).ready(function() {
    $("#continue").click(function() {
        $.ajax({
        url : '/finalize_userroles',
        type: "POST",
        data : $('spreadsheetfinalize').serialize(),
        success: function(data){
            $('#spreadsheet_finalize_items').html(data);
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
        }
      });
    });
    $("#skip").click(function() {
        $.ajax({
        url : '/finalize_userroles',
        type: "POST",
        data : $('spreadsheetfinalize').serialize()+"&skip=1",
        success: function(data){
            $('#spreadsheet_finalize_items').html(data);
        }
      });
    });
});
