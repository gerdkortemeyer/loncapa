$(document).ready(function() {
     $('#logoutbutton').click(function() {
         $.ajax({
             url: '/logout',
             type:'GET',
             success: function(response) {
                if (response=='error') {
                   $('.lcstandard').hide();
                   $('.lcerror').show();
                } else {
                   parent.hide_modal();
                }
                if (response=='ok') {
                   parent.dashboard();
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
