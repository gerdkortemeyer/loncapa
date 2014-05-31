$(document).ready(function() {
    $("#storebutton").click(function() {
        $.ajax({
        url : '/finalize_userroles',
        type: "POST",
        data : $('spreadsheetfinalize').serialize(),
        success: function(data){
            $('#spreadsheet_finalize_items').html(data);
        }
    });
  });
});
