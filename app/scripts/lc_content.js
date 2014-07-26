$(document).ready(function() {
  $('#content_tree').jstree({ 'core' : {
    'data' : {
      'url' : function (node) {
          return '/toc';
       },
       'data' : function (node) {
          return { 'id' : node.id };
       }
     }
  } });
  $('#content_tree').on("changed.jstree", function (e, data) {
    console.log(data.selected);
  });
});

function treereload() {
  $('#content_tree').jstree("refresh");
}
