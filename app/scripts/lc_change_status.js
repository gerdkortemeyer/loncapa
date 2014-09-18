var entity;
var domain;
var title;

function load_rights() {
  $.ajax({
             url: '/publisher',
             type:'POST',
             data: { 'command' : 'changestatus',
                     'entity'  : entity,
                     'domain'  : domain },
             success: function(response) {
                if (response=='error') {
                   $('.lcstandard').hide();
                   $('.lcerror').show();
                } else {
                   $("#rightslist").html(response);
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
     load_rights(); 
     $('#storebutton').click(function() {
        alert("Store");
     });
     $('#cancelbutton').click(function() {
        parent.hide_modal();
     });
});
