$(document).ready(function() {
     $('#loginbutton').click(function() {
         var data = $('#loginform').serialize();
         $.ajax({
             url: '/login',
             data: data,
             type:'POST',
             beforeSend: function() {
                 $.blockUI({
                 message: '<img src="/images/processing.gif" />',
                 css: {
                      border: 'none',
                      padding: '15px',
                      backgroundColor: '#ffffff',
                      'border-radius': '10px',
                      opacity: .5
                      }
                 });
             },
             complete: function () {
                $.unblockUI();
             },
             success: function(response) {
                if (response=='no') {
                   $('.lcstandard').hide();
                   $('.lcerror').hide();
                   $('.lcproblem').show();
                }
                if (response=='error') {
                   $('.lcstandard').hide();
                   $('.lcproblem').hide();
                   $('.lcerror').show();
                }
                if (response=='yes') {
                   parent.headerright();
                   var redirect=parent.getCookieByName(document.cookie,'lcredirect');
                   parent.deleteCookie('lcredirect');
                   parent.directjump(redirect);
                }
             },
             error: function(xhr, ajaxOptions, errorThrown) {
                $.unblockUI;
                $('.lcstandard').hide();
                $('.lcproblem').hide();
                $('.lcerror').show();
             }
         });         
     });
});
