$(document).ready(function() {
    $('#courselist').dataTable( {
      "oLanguage" : {
         "sUrl" : "/datatable_i14n"
      },
      "aoColumns" : [
         { "bSortable": false },
         null,
         null,
         null,
         null,
         null,
         null,
         {"iDataSort": 8},
         {"bVisible": false},
         {"iDataSort": 10},
         {"bVisible": false},
         null
      ]
    } );
} );
