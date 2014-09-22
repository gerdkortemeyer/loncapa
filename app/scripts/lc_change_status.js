var entity;
var domain;
var url;

function init_datatable(destroy) {

   var noCache = parent.no_cache_value();
   $('#rightslist').dataTable( {
      "sAjaxSource" : '/change_status?command=listrights&entity='+entity+'&domain='+domain+'&noCache='+noCache,
      "bAutoWidth": false,
      "bDestroy"  : destroy,
      "bStateSave": true,
      "oLanguage" : {
         "sUrl" : "/datatable_i14n"
      },
      "aoColumns" : [
         { "bVisible": false },
         { "bSortable": false },
         null,
         null,
         null,
         null
      ]
    } );
}

function reload_listing() {
   init_datatable(true);
}

function list_title() {
   $.ajax({
        url : '/change_status',
        type: "POST",
        data: 'command=listtitle&entity='+entity+'&domain='+domain+'&url='+url,
        success: function(data){
            $('#fileinfo').html(data);
        },
      }); 
}

function deleterule(entity,domain,rule) {
         $.ajax({
             url: '/change_status',
             type:'POST',
             data: { 'command' : 'delete',
                     'entity'  : entity,
                     'domain'  : domain,
                     'rule'    : unescape(rule) },
             success: function(response) {
                if (response=='error') {
                   $('.lcstandard').hide();
                   $('.lcerror').show();
                } else {
                   reload_listing();
                }
             },
             error: function(xhr, ajaxOptions, errorThrown) {
                $('.lcstandard').hide();
                $('.lcerror').show();
             }
         });
}

$(document).ready(function() {
     entity=parent.getParameterByName(location.search,'entity');
     domain=parent.getParameterByName(location.search,'domain');
     url=parent.getParameterByName(location.search,'url');
     list_title();
     init_datatable(false); 
     $('#donebutton').click(function() {
        parent.hide_modal();
     });
});
