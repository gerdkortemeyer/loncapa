var entity;
var domain;
var url;

function init_datatable() {

   var noCache = parent.no_cache_value();
   $('#rightslist').dataTable( {
      "sAjaxSource" : '/publisher?command=listrights&entity='+entity+'&domain='+domain+'&noCache='+noCache,
      "bAutoWidth": false, 
      "bStateSave": true,
      "oLanguage" : {
         "sUrl" : "/datatable_i14n"
      },
      "aoColumns" : [
         { "bVisible": false },
         null,
         null,
         null,
         null,
         null
      ]
    } );
}

function reload_listing() {
   $('#rightslist').dataTable().fnDestroy();
   init_datatable();
}

function list_title() {
   $.ajax({
        url : '/publisher',
        type: "POST",
        data: 'command=listtitle&entity='+entity+'&domain='+domain+'&url='+url,
        success: function(data){
            $('#fileinfo').html(data);
        },
      }); 
}

$(document).ready(function() {
     entity=parent.getParameterByName(location.search,'entity');
     domain=parent.getParameterByName(location.search,'domain');
     url=parent.getParameterByName(location.search,'url');
     list_title();
     init_datatable(); 
     $('#donebutton').click(function() {
        parent.hide_modal();
     });
});
