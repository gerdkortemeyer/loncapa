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

function attach_taxonomy() {
    $("#addtaxonomy").click(function() {
        $.ajax({
        url : '/publisher_screens',
        type: "POST",
        data : $('#publisherform').serialize()+"&addtaxonomy=1&returnstage=two",
        success: function(data){
            $('#publisher_screens').html(data);
        },
        complete: attach_taxonomy()
      });
     });
}

function attach_keywords() {
    $("#addkeywords").click(function() {
        $.ajax({
        url : '/publisher_screens',
        type: "POST",
        data : $('#publisherform').serialize()+"&returnstage=three",
        success: function(data){
            $('#publisher_screens').html(data);
        },
        complete: attach_keywords()
      });
     });
}

function show_continue() {
   $("#continue_span").show();
}

function hide_continue() {
   $("#continue_span").hide();
}
function show_back() {
   $("back_span").show();
}

function hide_back() {
   $("#back_span").hide();
}

function show_finalize() {
   $("finalize_span").show();
}

function hide_finalize() {
   $("#finalize_span").hide();
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
