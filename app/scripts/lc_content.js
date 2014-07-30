var edit_mode=false;

$(document).ready(function() {
  $('#content_tree').jstree({
     'plugins' : ['crrm','dnd','search'],
     'core' : {
        'check_callback' : true,
        'data' : {
           'url' : function (node) { return '/toc'; },
           'data' : function (node) { return { 'id' : node.id }; }
         }
     },
     'search' : { 'show_only_matches' : 1 }
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
      edit_mode=false;
   } else {
      edit_mode=true;
   }
}
