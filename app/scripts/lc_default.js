$(document).ready(function() {
   menubar();
   breadcrumbbar();
   notificationbox();
   checknotificationbox();
   dashboard();
});

$( window ).resize(function() {
   checknotificationbox();
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
      var frameheight=this.contentWindow.document.body.offsetHeight + 50;
      this.style.height = frameheight + 'px';
   });
}

function showsub (submenuelement) {
   $('#'+submenuelement).toggle();
}

function menubar() { 
$.getJSON( "menu", function( data ) {
  var newmenu = "<ul id='menubuttonrow' class='dropmenu'>";
  var func = new Array();
  var submenu=1;
  $.each(data, function(key, val) {
     if (typeof(val)=='object') {
        newmenu+="<li class='menucategory'><a href='#' onClick='showsub(\"submenu"+submenu+"\")'>"+key+"</a><ul id='submenu"+submenu+"'>";
        submenu++;
        $.each(val, function(subkey,subval) {
           if (typeof(subval)=='object') {
              newmenu+="<li class='menucategory'><a href='#' onClick='showsub(\"submenu"+submenu+"\")'>"+subkey+"</a><ul id='submenu"+submenu+"'>";
              submenu++;
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
   setbreadcrumbbar('fresh','logout','Logout','logout()');
   display_modal('/pages/lc_logout.html');
   menubar();
   breadcrumbbar();
}

function login() {
   setbreadcrumbbar('fresh','login','Login','login()');
   display_asset('/pages/lc_login.html');
   menubar();
   breadcrumbbar();
}

function dashboard() {
   setbreadcrumbbar('fresh','dashboard','Dashboard','dashboard()');
   display_asset("/pages/lc_dashboard.html");
   menubar();
   breadcrumbbar();
}

function portfolio() {
   setbreadcrumbbar('fresh','portfolio','Portfolio','portfolio()');
   display_asset("/pages/lc_portfolio.html");
   menubar();
   breadcrumbbar();
}

function preferences() {
   setbreadcrumbbar('fresh','preferences','Preferences','preferences()');
   display_asset("/pages/lc_preferences.html");
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
     func=val.split("&");
     newmenu+="<li class='breadcrumb' id='"+key+"'><a href='#' onClick='"+func[1]+"'>"+func[0]+"</a></li>";
  });
  newmenu+="</ul>";
  $("#breadcrumbrow").replaceWith(newmenu);
});
}

function setbreadcrumbbar(mode,title,text,func) {
$.post( "breadcrumbs",$.parseJSON('{"mode":"'+mode+'","title":"'+title+'","text":"'+text+'","function":"'+func+'"}'));
}

function checknotificationbox() {
   if ($(window).width()<680) {
      $("aside").hide();
      $("section").css("right","5px");
      $("footer").css("right","5px");
   } else {
      $("section").css("right","168px");
      $("footer").css("right","168px");
      $("aside").show();
   }
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
