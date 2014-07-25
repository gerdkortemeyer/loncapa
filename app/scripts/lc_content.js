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
});

