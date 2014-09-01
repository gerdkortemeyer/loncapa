var edit_mode=false;

$(document).ready(function() {
  $('#content_tree').jstree({
     'plugins' : ['dnd','search','contextmenu','types'],
     'core' : {
        'check_callback' : function(operation, node, node_parent, node_position, more) { return edit_mode; },
        'data' : {
           'url' : function (node) { return '/toc'; },
           'data' : function (node) { return { 'id' : node.id }; }
         }
     },
     'search' : { 'show_only_matches' : 1 },
     'dnd' : {
        'open_timeout' : 100,
     }
  });
  var to = false;
  $('#content_tree_q').keyup(function () {
    if (to) { clearTimeout(to); }
    to = setTimeout(function () {
       var v = $('#content_tree_q').val();
       $('#content_tree').jstree(true).search(v);
       }, 100);
  });
  $('#content_tree').on("changed.jstree", function (e, data) {
     if ((data.selected) && (!edit_mode)) {
        parent.display_course_asset(data.instance.get_node(data.selected[0]).id);
     } else {
        adjust_framesize();
     }
  });
  $("#content_tree").on("after_open.jstree", function () {
     adjust_framesize();
  });
  $("#content_tree").on("after_close.jstree", function () {
     adjust_framesize();
  })
  $('#content_tree').on("loaded.jstree", function (e, data) {
     adjust_framesize();
  });
});

function treereload() {
  $('#content_tree').jstree("refresh");
}

function toggle_edit() {
   if (edit_mode) {
      $('#edit_lock').attr('src','/images/lock_closed.png');
      $('#instructions').hide();
      edit_mode=false;
   } else {
      $('#edit_lock').attr('src','/images/lock_opened.png');
      $('#instructions').show();
      edit_mode=true;
   }
}
