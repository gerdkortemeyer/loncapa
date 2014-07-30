var edit_mode=false;

$(document).ready(function() {
  $('#content_tree').jstree({
     'plugins' : ['dnd','search'],
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
       }, 250);
  });
  $('#content_tree').on("changed.jstree", function (e, data) {
    console.log(JSON.stringify(data.selected));
  });
});

function treereload() {
  $('#content_tree').jstree("refresh");
}

function toggle_edit() {
   if (edit_mode) {
      $('#edit_lock').attr('src','/images/lock_closed.png');
      edit_mode=false;
   } else {
      $('#edit_lock').attr('src','/images/lock_opened.png');
      edit_mode=true;
   }
}
