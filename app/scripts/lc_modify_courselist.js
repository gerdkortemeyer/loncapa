var followup=0;
var error=1;
var list_context=0;

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
    $('#cancelbutton').click(function() {
        parent.hide_modal();
    });
});

function runbackground() {
   $.ajax({
        url : '/finalize_modify_courseusers',
        type: "POST",
        data: $('#modify_courseusers').serialize()+"&stage_three=1",
        success: function(data){
            $('#messages').html(data);
            back_to_list();
        },
        error: function() {
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

function back_to_list() {
    if (list_context) {
        parent.hide_modal();
        parent.document.getElementById('contentframe').contentWindow.update_selected();
    }
}
