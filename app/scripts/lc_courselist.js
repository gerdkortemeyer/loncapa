$(document).ready(function() {
    $('#courselist').dataTable( {
      "oLanguage" : {
         "sUrl" : "/datatable_i14n"
      },
      "aoColumns" : [
         { "bSortable": false },
         null,
         {"bVisible": false},
         null,
         {"bVisible": false},
         {"bVisible": false},
         {"bVisible": false},
         {"bVisible": false},
         null,
         null,
         {"iDataSort": 11,"bVisible": false},
         {"bVisible": false},
         {"iDataSort": 13,"bVisible": false},
         {"bVisible": false},
         null
      ]
    } );
} );

function fnShowHide( iCol ) {
   var oTable = $('#courselist').dataTable();
   var bVis = oTable.fnSettings().aoColumns[iCol].bVisible;
   oTable.fnSetColumnVis( iCol, bVis ? false : true );
}
