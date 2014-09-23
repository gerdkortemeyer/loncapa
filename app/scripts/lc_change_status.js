var entity;
var domain;
var url;
var savechanges;

function init_datatable(destroy,newrule) {

   var noCache = parent.no_cache_value();
   $('#rightslist').dataTable( {
      "sAjaxSource" : '/change_status?command=listrights&entity='+entity+'&domain='+domain+'&newrule='+newrule+'&noCache='+noCache,
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

function reload_listing(newrule) {
   init_datatable(true,newrule);
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
                   reload_listing(0);
                }
             },
             error: function(xhr, ajaxOptions, errorThrown) {
                $('.lcstandard').hide();
                $('.lcerror').show();
             }
         });
}

function discardrule() {
   savechanges=false;
   reload_listing(0);
}

function saverules() {
   savechanges=false;
   alert("Saving");
}

$(document).ready(function() {
     savechanges=false;
     entity=parent.getParameterByName(location.search,'entity');
     domain=parent.getParameterByName(location.search,'domain');
     url=parent.getParameterByName(location.search,'url');
     list_title();
     init_datatable(false,0); 
     $('#donebutton').click(function() {
        if (savechanges) { saverules(); }
        parent.hide_modal();
     });
     $('#addbutton').click(function() {
        if (savechanges) { saverules(); }
        reload_listing(1);
     });
});
