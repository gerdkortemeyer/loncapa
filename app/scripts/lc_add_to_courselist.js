$(document).ready(function() {
    $('#continue').click(function() {
        modify_selected();
    });
} );

function modify_selected() {
   if ($('#user_username').val().length>0) {
      document.searchnewuser.method="post";
      document.searchnewuser.action="/pages/lc_modify_courselist.html";
      parent.setbreadcrumbbar('add','modifycourselist','Modify Selected Entries','');
      parent.breadcrumbbar();
      document.searchnewuser.submit();
   }
}
