var followup=0;
var error=1;

$(document).ready(function() {
    showhide();
    $("#continue").click(function() {
        $.ajax({
        url : '/finalize_modify_courseusers',
        type: "POST",
        data : $('#modify_courseusers').serialize()+"&stage_two=1",
        success: function(data){
            $('#modify_courseusers_finalize').html(data);
        },
        complete: function() {
            showhide();
            adjust_framesize();
        }
      });
    });
});

function runbackground() {
   $.ajax({
        url : '/finalize_modify_courseusers',
        type: "POST",
        data: $('#modify_courseusers').serialize()+"&stage_three=1",
        success: function(data){
            $('#modify_courseusers_finalize').html(data);
        },
        complete: function() {
            showhide();
            adjust_framesize();
        }
      });
}

function showhide() {
   if (followup==1) {
      $('.lcproblem').show();
      $('.lcsuccess').hide();
   } else {
      $('.lcproblem').hide();
      $('.lcsuccess').show();
   }
   if (error==1) {
      $('.lcsuccess').hide();
      $('.lcerror').show();
   } else {
      $('.lcsuccess').show();
      $('.lcerror').hide();
   }
}

