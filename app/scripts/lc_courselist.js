$(document).ready(function() {

    $('#courseuserlist tr').click( function() {
                if ( $(this).hasClass('row_selected') ) {
                        $(this).removeClass('row_selected');
                } else {
                        $(this).addClass('row_selected');
                }
    } );

    $('#courseuserlist').dataTable( {
      "bStateSave": true,
      "oLanguage" : {
         "sUrl" : "/datatable_i14n"
      },
      "aoColumns" : [
         { "bVisible": false },
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

    $('#newbutton').click(function() {
        parent.add_to_courselist();
    });

    $('#modifybutton').click(function() {
        modify_selected();
    });
} );

function fnShowHide( iCol ) {
   var oTable = $('#courseuserlist').dataTable();
   var bVis = oTable.fnSettings().aoColumns[iCol].bVisible;
   oTable.fnSetColumnVis( iCol, bVis ? false : true );
   adjust_framesize();
}

function select_filtered() {
   var oTable = $('#courseuserlist').dataTable();
   var aTrs = oTable.$('tr', {"filter":"applied"});
   for ( var i=0 ; i<aTrs.length ; i++ ) {
      $(aTrs[i]).addClass('row_selected');
   }
}

function select_all() {
   var oTable = $('#courseuserlist').dataTable();
   var aTrs = oTable.fnGetNodes();
   for ( var i=0 ; i<aTrs.length ; i++ ) {
      $(aTrs[i]).addClass('row_selected');
   }
}

function deselect_all() {
   var oTable = $('#courseuserlist').dataTable();
   var aTrs = oTable.fnGetNodes();
   for ( var i=0 ; i<aTrs.length ; i++ ) {
      $(aTrs[i]).removeClass('row_selected');
   }
}

function fnGetSelected() {
   var aReturn = new Array();
   var oTable = $('#courseuserlist').dataTable();
   var aTrs = oTable.fnGetNodes();	
   for ( var i=0 ; i<aTrs.length ; i++ ) {
      if ( $(aTrs[i]).hasClass('row_selected') ) {
	 aReturn.push( '{ entity: "'+oTable.fnGetData(aTrs[i],0)+'",domain: "'+oTable.fnGetData(aTrs[i],6)+'" }' );
      }
   }
   return '['+aReturn.join(',')+']';
}

function modify_selected() {
   var selectedUsers=fnGetSelected();
   alert(selectedUsers);
}
