$(document).ready(function() {
     $('#storebutton').click(function() {
        if (completed()) {
           $('.lcproblem').hide();
           document.spreadsheetassign.method="post";
           document.spreadsheetassign.action="/pages/lc_upload_users_to_courselist_finalize.html";
           parent.setbreadcrumbbar('add','finalizeuploadcourselist','Finalize','');
           parent.breadcrumbbar();
           $('#spreadsheetassign').trigger('submit');
        } else {
           $('.lcproblem').show();
        }
     });
     verify();
});

function completed() {
   var foundit=false;
   $('.lcformselectinput').each(function() {
      if (($(this).val()=='username') ||
          ($(this).val()=='userpid') ||
          ($(this).val()=='useremail')) {
         foundit=true;
      }
   });
   return foundit;
}

function verify(changedentry) {
   var fieldname='void';
   var fieldvalue='';
   if (!(typeof(changedentry)==='undefined')) {
      fieldname=changedentry.name;
      fieldvalue=$('#'+fieldname).val();
   }
   var founddomain=false;
   var foundpassword=false;
   var foundrole=false;
   var foundsection=false;
   var foundstartdate=false;
   var foundenddate=false;
   $('.lcformselectinput').each(function() {
       if ($(this).attr('name')!=fieldname) {
          if ($(this).val()==fieldvalue) {
             $(this).val('nothing');
          }
          if (fieldvalue=='namecombi') {
             if (($(this).val()=='firstname') ||
                 ($(this).val()=='middlename') ||
                 ($(this).val()=='lastname')) {
                $(this).val('nothing');
             }
          }
          if ((fieldvalue=='firstname') ||
              (fieldvalue=='middlename') ||
              (fieldvalue=='lastname')) {
             if ($(this).val()=='namecombi') {
                $(this).val('nothing');
             }
          }
          if (fieldvalue=='userpid') {
             if (($(this).val()=='username') ||
                 ($(this).val()=='pid') ||
                 ($(this).val()=='useremail') ||
                 ($(this).val()=='passwordpid')) {
                $(this).val('nothing');
             }
          }
          if ((fieldvalue=='username') ||
              (fieldvalue=='pid')) {
             if ($(this).val()=='userpid') {
                $(this).val('nothing');
             }
          }
         if (fieldvalue=='useremail') {
             if (($(this).val()=='username') ||
                 ($(this).val()=='email') ||
                 ($(this).val()=='userpid')) {
                $(this).val('nothing');
             }
          }
          if ((fieldvalue=='username') ||
              (fieldvalue=='email')) {
             if ($(this).val()=='useremail') {
                $(this).val('nothing');
             }
          }
         if (fieldvalue=='passwordpid') {
             if (($(this).val()=='password') ||
                 ($(this).val()=='pid') ||
                 ($(this).val()=='userpid')) {
                $(this).val('nothing');
             }
          }
          if ((fieldvalue=='password') ||
              (fieldvalue=='pid')) {
             if ($(this).val()=='passwordpid') {
                $(this).val('nothing');
             }
          }
       }
       if ($(this).val()=='domain') {
          founddomain=true;
       }
       if (($(this).val()=='password') ||
           ($(this).val()=='passwordpid')) {
          foundpassword=true;
       }
       if ($(this).val()=='role') {
          foundrole=true;
       }
       if ($(this).val()=='startdate') {
          foundstartdate=true;
       }
       if ($(this).val()=='enddate') {
          foundenddate=true;
       }
       if ($(this).val()=='section') {
          foundsection=true;
       }
   });
   if (founddomain) {
      $("#defaultdomain").prop("disabled",true);
   } else {
      $("#defaultdomain").prop("disabled",false);
   }
   if (foundpassword) {
      $("#defaultpassword").prop("disabled",true);
   } else {
      $("#defaultpassword").prop("disabled",false);
   }
   if (foundrole) {
      $("#defaultrole").prop("disabled",true);
   } else {
      $("#defaultrole").prop("disabled",false);
   }
   if (foundsection) {
      $("#defaultsection").prop("disabled",true);
   } else {
      $("#defaultsection").prop("disabled",false);
   }
   if (foundstartdate) {
      $("#defaultstartdate").prop("disabled",true);
   } else {
      $("#defaultstartdate").prop("disabled",false);
   }
   if (foundenddate) {
      $("#defaultenddate").prop("disabled",true);
   } else {
      $("#defaultenddate").prop("disabled",false);
   }
}
