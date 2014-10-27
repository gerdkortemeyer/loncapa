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
        data : $('#publisherform').serialize()+"&addlanguage=1&returnstage=1",
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
        data : $('#publisherform').serialize()+"&addtaxonomy=1&returnstage=2",
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
        data : $('#publisherform').serialize()+"&returnstage=3",
        success: function(data){
            $('#publisher_screens').html(data);
        },
        complete: attach_keywords()
      });
     });
}

function show_continue() {
   document.getElementById('continue_span').style.display = "inline";
}

function hide_continue() {
   document.getElementById('continue_span').style.display = "none";
}

function show_back() {
   document.getElementById('back_span').style.display = "inline";
}

function hide_back() {
   document.getElementById('back_span').style.display = "none";
}

function show_finalize() {
   document.getElementById('finalize_span').style.display = "inline";
}

function hide_finalize() {
   document.getElementById('finalize_span').style.display = "none";
}

function buttons() {
   if ($('#stage').val()>1) {
      show_back();
   } else {
      hide_back();
   }
   if ($('#stage').val()==4) {
      hide_continue();
      show_finalize();
   } else {
      show_continue();
      hide_finalize();
   }
}

$(document).ready(function() {
     entity=parent.getParameterByName(location.search,'entity');
     domain=parent.getParameterByName(location.search,'domain');
     url=parent.getParameterByName(location.search,'url');
     list_title();
     hide_back();
     hide_finalize();
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
        },
        complete: function(){
           buttons();
           list_title();
        }
      });
    });

    $("#finalize").click(function() {
        $.ajax({
        url : '/publisher_screens',
        type: "POST",
        data : $('#publisherform').serialize()+"&finalize=1",
        success: function(response) {
                if (response=='ok') {
                   $('.lcerror').hide();
                   parent.document.getElementById('contentframe').contentWindow.reload_listing();
                   parent.hide_modal();
                } else {
                   $('.lcerror').show();
                }
        }
      });
    });


    $("#back").click(function() {
        $.ajax({
        url : '/publisher_screens',
        type: "POST",
        data : $('#publisherform').serialize()+"&returnstage="+($('#stage').val()-1),
        success: function(data){
            $('#publisher_screens').html(data);
        },
        complete: function(){
           buttons();
        }
      });
     });

});
