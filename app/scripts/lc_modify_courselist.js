var followup=0;
var error=1;

$(document).ready(function() {
    showhide();
});


function showhide() {
   if (followup==1) {
      $('.lcproblem').show();
      $('.lcsuccess').hide();
   } else {
      $('.lcproblem').hide();
      $('.lcsuccess').show();
   }
   if (error==1) {
      $('.lcsuccess').hide();
      $('.lcerror').show();
   } else {
      $('.lcsuccess').show();
      $('.lcerror').hide();
   }
}

