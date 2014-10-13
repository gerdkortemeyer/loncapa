var entity;
var domain;
var url;

function list_title() {
   $.ajax({
        url : '/change_status',
        type: "POST",
        data: 'command=listtitle&entity='+entity+'&domain='+domain+'&url='+url,
        success: function(data){
            $('#fileinfo').html(data);
        }
      }); 
}

function attach_language() {
    $("#addlanguage").click(function() {
        $.ajax({
        url : '/publisher_screens',
        type: "POST",
        data : $('#publisherform').serialize()+"&addlanguage=1&returnstage=one",
        success: function(data){
            $('#publisher_screens').html(data);
        },
        complete: attach_language()
      });
     });
}


$(document).ready(function() {
     entity=parent.getParameterByName(location.search,'entity');
     domain=parent.getParameterByName(location.search,'domain');
     url=parent.getParameterByName(location.search,'url');
     list_title();
     $('#cancel').click(function() {
        parent.document.getElementById('contentframe').contentWindow.reload_listing();
        parent.hide_modal();
     });

     $("#continue").click(function() {
        $.ajax({
        url : '/publisher_screens',
        type: "POST",
        data : $('#publisherform').serialize(),
        success: function(data){
            $('#publisher_screens').html(data);
        }
      });
     });

});
