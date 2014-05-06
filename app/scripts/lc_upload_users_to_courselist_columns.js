$(document).ready(function() {
     $('#storebutton').click(function() {
        if (completed()) {
           alert('okay');
        } else {
           alert('problem!');
        }
     });
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
   var fieldname=changedentry.name;
   var fieldvalue=$('#'+fieldname).val();
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
   });
}
