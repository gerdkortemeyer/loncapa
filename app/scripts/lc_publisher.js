var entity;
var domain;
var url;

function reload_listing() {
   $('#rightslist').dataTable().fnDestroy();
   init_datatable();
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

$(document).ready(function() {
     entity=parent.getParameterByName(location.search,'entity');
     domain=parent.getParameterByName(location.search,'domain');
     url=parent.getParameterByName(location.search,'url');
     list_title();
     $('#cancelbutton').click(function() {
        parent.hide_modal();
     });
});
