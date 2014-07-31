var serial=0;

$(document).ready(function() {
   menubar();
   breadcrumbbar();
   notificationbox();
   checknotificationbox();
   dashboard();
   headerright();
   headermiddle();
});

$( window ).resize(function() {
   checknotificationbox();
});

function display_modal(newuri) {
    $.blockUI({
                 message: '<iframe id="lcmodal" width="100%" height="100%" src="'+newuri+'" />',
                 css: {
                      border: 'none',
                      padding: '15px',
                      width: '400px',
                      height: '300px',
                      backgroundColor: '#ffffff',
                      'border-radius': '10px'
                      }
                 });
    $("#lcmodal").focus();
}

function hide_modal() {
   $.unblockUI();
}

function display_course_asset(assetid) {
   $.getJSON( "toc", { "command" : "data", "assetid" : assetid }, function( data ) {
       $.each(data, function(key, val) {
           if (key=='url') {
              var newcontent='<div id="content"><iframe id="contentframe" src="'+val+'"></iframe></div>';
              $('#contentframeload').css("visibility","visible");
              $('#content').replaceWith(newcontent);
              $('#contentframe').load(function() {
                 var frameheight=this.contentWindow.document.body.offsetHeight + 50;
                 this.style.height = frameheight + 'px';
                 $('#contentframeload').css("visibility","hidden");
              });
              show_navarrows();
           }
       });
   });
}

function display_asset(newuri) {
   var newcontent='<div id="content"><iframe id="contentframe" src="'+newuri+'"></iframe></div>';
   $('#contentframeload').css("visibility","visible");
   $('#content').replaceWith(newcontent);
   $('#contentframe').load(function() {
      var frameheight=this.contentWindow.document.body.offsetHeight + 50;
      this.style.height = frameheight + 'px';
      $('#contentframeload').css("visibility","hidden");
   });
   hide_navarrows();
}

function show_navarrows() {
   $('#content').css('width','94%');
   $('#navleft').css('width','3%');
   $('#navright').css('width','3%');
   $('#navleft').html('&lt;');
   $('#navright').html('&gt;');
}

function hide_navarrows() {
   $('#navleft').html('');
   $('#navright').html('');
   $('#navleft').css('width','0%');
   $('#navright').css('width','0%');
   $('#content').css('width','100%');
}


function showsub (submenuelement) {
   if (!($('#open'+submenuelement).is(":hover"))) {
      if ($('#submenu'+submenuelement).is(":visible")) {
         $('#submenu'+submenuelement).css("visibility","hidden");
         $('#submenu'+submenuelement).hide();
      } else {
         $('#submenu'+submenuelement).css("visibility","visible");
         $('#submenu'+submenuelement).show();
      }
   }
}

function no_cache_value() {
   var noCache=new Date().getTime();
   serial++;
   if (serial>1000000) { serial=0; }
   noCache += '_' + serial;
   return noCache;
}

function menubar() {
var noCache = no_cache_value();
$.getJSON( "menu", { "noCache": noCache }, function( data ) {
  var newmenu = "<ul id='menubuttonrow' class='dropmenu'>";
  var func = new Array();
  var submenu=1;
  $.each(data, function(key, val) {
     if (typeof(val)=='object') {
        newmenu+="<li class='menucategory'><a href='#' id='open"+submenu+"' onClick='showsub(\""+submenu+"\")'>"+key+"</a><ul id='submenu"+submenu+"'>";
        submenu++;
        $.each(val, function(subkey,subval) {
           if (typeof(subval)=='object') {
              newmenu+="<li class='menucategory'><a href='#' id='open"+submenu+"' onClick='showsub(\""+submenu+"\")'>"+subkey+"</a><ul id='submenu"+submenu+"'>";
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

function busy_block() {
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
}

function busy_unblock() {
   $.unblockUI();
}


function content() {
   setbreadcrumbbar('fresh','content','Content','content()');
   display_asset("/pages/lc_content.html");
   menubar();
   breadcrumbbar();
}

function courselist() {
   setbreadcrumbbar('fresh','courselist','Enrollment List','courselist()');
   display_asset("/pages/lc_courselist.html");
   menubar();
   breadcrumbbar();
}

function add_to_courselist() {
   setbreadcrumbbar('add','addcourselist','Add New Entry','add_to_courselist()');
   display_asset("/pages/lc_add_to_courselist.html");
   menubar();
   breadcrumbbar();
}

function add_user_to_courselist() {
   setbreadcrumbbar('fresh','addcourselist','Manually Enroll User','add_user_to_courselist()');
   display_asset("/pages/lc_add_to_courselist.html");
   menubar();
   breadcrumbbar();
}

function upload_users_to_courselist() {
   setbreadcrumbbar('fresh','uploadcourselist','Upload List','upload_users_to_courselist()');
   display_asset("/pages/lc_upload_users_to_courselist.html");
   menubar();
   breadcrumbbar();
}

function upload_users_to_courselist_columns() {
   setbreadcrumbbar('add','uploadcourselistcolumns','Identify Columns','upload_users_to_courselist_columns()');
   display_asset("/pages/lc_upload_users_to_courselist_columns.html");
   menubar();
   breadcrumbbar();
}


function grading() {
   setbreadcrumbbar('fresh','grading','Grading','grading()');
   display_asset("/pages/lc_grading.html");
   menubar();
   breadcrumbbar();
}

function my_grades() {
   setbreadcrumbbar('fresh','my_grades','My Grades','my_grades()');
   display_asset("/pages/lc_my_grades.html");
   menubar();
   breadcrumbbar();
}

function logout() {
   setbreadcrumbbar('fresh','logout','Logout','logout()');
   display_modal('/modals/lc_logout.html');
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

function courses() {
   setbreadcrumbbar('fresh','courses','Courses','courses()');
   display_asset("/pages/lc_courses.html");
   menubar();
   breadcrumbbar();
}

function communities() {
   setbreadcrumbbar('fresh','communities','Communities','communities()');
   display_asset("/pages/lc_communities.html");
   menubar();
   breadcrumbbar();
}

function messages() {
   setbreadcrumbbar('fresh','messages','Messages','messages()');
   display_asset("/pages/lc_messages.html");
   menubar();
   breadcrumbbar();
}

function calendar() {
   setbreadcrumbbar('fresh','calendar','Calendar','calendar()');
   display_asset("/pages/lc_calendar.html");
   menubar();
   breadcrumbbar();
}

function listbookmarks() {
   setbreadcrumbbar('fresh','listbookmarks','Bookmarks','listbookmarks()');
   display_asset("/pages/lc_bookmarks.html");
   menubar();
   breadcrumbbar();
}

function setbookmark() {
   display_modal('/pages/lc_setbookmark.html');
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

function coursepreferences() {
   setbreadcrumbbar('fresh','preferences','Preferences','coursepreferences()');
   display_asset("/pages/lc_course_preferences.html");
   menubar();
   breadcrumbbar();
}


function help() {
   display_asset("/help/lc_help.html");
   breadcrumbbar();
}

function breadcrumbbar() {
var noCache = no_cache_value();
$.getJSON( "breadcrumbs", { "noCache": noCache }, function( data ) {
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

function headerright() {
var noCache = no_cache_value();
$.getJSON( "headerright", { "noCache": noCache }, function( data ) {
  var newheader = "<div id='headerright'>";
  $.each( data, function( key, val ) {
     newheader+=val;
  });
  newheader+="</div>";
  $("#headerright").replaceWith(newheader);
});
}

function headermiddle() {
var noCache = no_cache_value();
$.getJSON( "headermiddle", { "noCache": noCache }, function( data ) {
  var newheader = "<div id='headermiddle'>";
  $.each( data, function( key, val ) {
     newheader+=val;
  });
  newheader+="</div>";
  $("#headermiddle").replaceWith(newheader);
});
}


function checknotificationbox() {
   if ($(window).width()<680) {
      $("aside").hide();
      $("section").css("right","5px");
      $("footer").css("right","5px");
   } else {
      $("section").css("right","162px");
      $("footer").css("right","162px");
      $("aside").show();
   }
}

function notificationbox() {
var noCache = no_cache_value();
$.getJSON( "notifications", { "noCache": noCache }, function( data ) {
  var newmenu = "<ul id='notifications'>";
  $.each( data, function( key, val ) {
    newmenu+="<li class='notification' id='" + key + "'>" + val + "</li>";
  });
  newmenu+="</ul>";
  $("#notifications").replaceWith(newmenu);
});
setTimeout(notificationbox,30000);
}
