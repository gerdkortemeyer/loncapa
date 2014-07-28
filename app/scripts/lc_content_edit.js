$(document).ready(function() {
  $('#content_tree').jstree({ 'core' : {
    'check_callback' : true,
    'data' : {
      'url' : function (node) {
          return '/toc';
       },
       'data' : function (node) {
          return { 'id' : node.id };
       }
     }
   },
   'plugins' : ['dnd'] 
  });
  $('#content_tree').on("changed.jstree", function (e, data) {
    console.log(data.selected);
  });
});

function treereload() {
  $('#content_tree').jstree("refresh");
}
