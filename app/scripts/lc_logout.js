$(document).ready(function() {
     $('#logoutbutton').click(function() {
         $.ajax({
             url: '/logout',
             type:'POST',
             success: function(response) {
                if (response=='error') {
                   $('.lcstandard').hide();
                   $('.lcerror').show();
                } else {
                   parent.hide_modal();
                }
                if (response=='ok') {
                   parent.headermiddle();
                   parent.headerright();
                   parent.login();
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
