$(document).ready(function() {
     $.ajaxSetup({ cache: false });
     $('#storebutton').click(function() {
         var data = $('#preferencesform').serialize();
         $.ajax({
             url: '/preferences',
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
                   $('.lcsuccess').hide();
                   $('.lcproblem').show();
                }
                if (response=='error') {
                   $('.lcstandard').hide();
                   $('.lcproblem').hide();
                   $('.lcsuccess').hide();
                   $('.lcerror').show();
                }
                if (response=='yes') {
                   $('.lcstandard').hide();
                   $('.lcproblem').hide();
                   $('.lcerror').hide();
                   $('.lcsuccess').show();
                }
             },
             error: function(xhr, ajaxOptions, errorThrown) {
                $.unblockUI;
                $('.lcstandard').hide();
                $('.lcproblem').hide();
                $('.lcsuccess').hide();
                $('.lcerror').show();
             }
         });         
     });
});
