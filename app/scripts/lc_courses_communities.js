$(document).ready(function() {
    $('#courselist').dataTable( {
      "oLanguage" : {
         "sUrl" : "/datatable_i14n"
      },
      "aoColumns" : [
         { "bSortable": false },
         null,
         null,
         null
      ]
    } );
} );

function select_course (entity,domain) {
   alert(entity+' '+domain);
}
