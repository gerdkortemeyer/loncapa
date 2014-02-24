$(document).ready(function() {
   menubar();
   breadcrumbbar();
   notificationbox();
   dashboard();
});

function display_modal(newuri) {
    $.blockUI({
                 message: '<iframe width="100%" height="100%" src="'+newuri+'" />',
                 css: {
                      border: 'none',
                      padding: '15px',
                      width: '400px',
                      height: '300px',
                      backgroundColor: '#ffffff',
                      'border-radius': '10px',
                      }
                 });
}

function hide_modal() {
   $.unblockUI();
}

function display_asset(newuri) {
   var newcontent='<div id="content"><iframe id="contentframe" src="'+newuri+'"></iframe></div>';
   $('#content').replaceWith(newcontent);
   $('#contentframe').load(function() {
      var frameheight=this.contentWindow.document.body.offsetHeight + 40;
      this.style.height = frameheight + 'px';
   });
}

function menubar() { 
$.getJSON( "menu", function( data ) {
  var newmenu = "<ul id='menubuttonrow' class='dropmenu'>";
  var func = new Array();
  $.each(data, function(key, val) {
     if (typeof(val)=='object') {
        newmenu+="<li class='menucategory'>"+key+"<ul>";
        $.each(val, function(subkey,subval) {
           if (typeof(subval)=='object') {
              newmenu+="<li class='menucategory'>"+subkey+"<ul>";
              $.each(subval, function(subsubkey,subsubval) {
                 func=subsubval.split("&");
                 newmenu+="<li id='"+subsubkey+"' class='menulink'><a href='#' onClick='"+func[1]+"'>"+func[0]+"</a></li>";
              });
              newmenu+="</ul></li>";
           } else {
              func=subval.split("&");
              newmenu+="<li id='"+subkey+"' class='menulink'><a href='#' onClick='"+func[1]+"'>"+func[0]+"</a></li>";
           }
        });
        newmenu+="</ul></li>";
     } else {
        func=val.split("&");
        newmenu+="<li id='"+key+"' class='menulink'><a href='#' onClick='"+func[1]+"'>"+func[0]+"</a></li>";
     }
  });
  newmenu+="</ul>";
  $("#menubuttonrow").replaceWith(newmenu);
});
}

function logout() {
   display_modal('/pages/lc_logout.html');
   menubar();
   breadcrumbbar();
}

function login() {
   display_asset('/pages/lc_login.html');
   menubar();
   breadcrumbbar();
}

function dashboard() {
   display_asset("/pages/lc_dashboard.html");
   menubar();
   breadcrumbbar();
}

function help() {
   display_asset("/help/lc_help.html");
   breadcrumbbar();
}

function breadcrumbbar() {
$.getJSON( "breadcrumbs", function( data ) {
  var newmenu = "<ul id='breadcrumbrow'>";
  $.each( data, function( key, val ) {
    newmenu+="<li class='breadcrumb' id='" + key + "'><a href='#'>" + val + "</a></li>";
  });
  newmenu+="</ul>";
  $("#breadcrumbrow").replaceWith(newmenu);
});
}

function notificationbox() {
$.getJSON( "notifications", function( data ) {
  var newmenu = "<ul id='notifications'>";
  $.each( data, function( key, val ) {
    newmenu+="<li class='notification' id='" + key + "'>" + val + "</li>";
  });
  newmenu+="</ul>";
  $("#notifications").replaceWith(newmenu);
});
setTimeout(notificationbox,30000);
}

function testupdates() {
   menubar();
   breadcrumbbar();
}
