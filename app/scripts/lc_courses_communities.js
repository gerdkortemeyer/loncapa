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
