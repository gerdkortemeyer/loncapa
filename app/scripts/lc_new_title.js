var entity;
var domain;
var title;

$(document).ready(function() {
     entity=parent.getParameterByName(location.search,'entity');
     domain=parent.getParameterByName(location.search,'domain');
     title=parent.getParameterByName(location.search,'title');
     $('#newtitle').val(title);
     $('#storebutton').click(function() {
         $.ajax({
             url: '/portfolio',
             type:'POST',
             success: function(response) {
                if (response=='error') {
                   $('.lcstandard').hide();
                   $('.lcerror').show();
                } else {
                   parent.hide_modal();
                }
             },
             error: function(xhr, ajaxOptions, errorThrown) {
                $('.lcstandard').hide();
                $('.lcerror').show();
             }
         });         
     });
     $('#cancelbutton').click(function() {
        parent.hide_modal();
     });
});
