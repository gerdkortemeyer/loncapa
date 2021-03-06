var showhidden=0;

$(document).ready(function() {

    init_datatable(false);

    load_path();

    $('#newbutton').click(function() {
        parent.add_to_courselist();
    });

    $('#modifybutton').click(function() {
        modify_selected();
    });
} );

function hiddenvisible() {
   if (showhidden) {
      showhidden=0;
   } else {
      showhidden=1;
   }
   reload_listing();
}

function change_title(entity,domain,url,title) {
   parent.display_modal('/modals/lc_new_title.html?domain='+domain+'&entity='+entity+'&url='+url+'&title='+title);
}

function change_status(entity,domain,url) {
   parent.display_large_modal('/modals/lc_change_status.html?domain='+domain+'&entity='+entity+'&url='+url);
}

function publisher(entity,domain,url) {
   parent.display_large_modal('/modals/lc_publisher.html?domain='+domain+'&entity='+entity+'&url='+url);
}

function recover(entity,domain,url) {
         $.ajax({
             url: '/portfolio',
             type:'POST',
             data: { 'command' : 'recover',
                     'entity'  : entity,
                     'domain'  : domain,
                     'url'     : unescape(url) },
             success: function(response) {
                if (response=='error') {
                   $('.lcstandard').hide();
                   $('.lcerror').show();
                } else {
                   reload_listing();
                }
             },
             error: function(xhr, ajaxOptions, errorThrown) {
                $('.lcstandard').hide();
                $('.lcerror').show();
             }
         });         
}

function removefile(entity,domain,url) {
         $.ajax({
             url: '/portfolio',
             type:'POST',
             data: { 'command' : 'remove',
                     'entity'  : entity,
                     'domain'  : domain,
                     'url'     : unescape(url) },
             success: function(response) {
                if (response=='error') {
                   $('.lcstandard').hide();
                   $('.lcerror').show();
                } else {
                   reload_listing();
                }
             },
             error: function(xhr, ajaxOptions, errorThrown) {
                $('.lcstandard').hide();
                $('.lcerror').show();
             }
         });
}

function deletefile(entity,domain,url) {
         $.ajax({
             url: '/portfolio',
             type:'POST',
             data: { 'command' : 'delete',
                     'entity'  : entity,
                     'domain'  : domain,
                     'url'     : unescape(url) },
             success: function(response) {
                if (response=='error') {
                   $('.lcstandard').hide();
                   $('.lcerror').show();
                } else {
                   reload_listing();
                }
             },
             error: function(xhr, ajaxOptions, errorThrown) {
                $('.lcstandard').hide();
                $('.lcerror').show();
             }
         });
}

function downloadfile(entity,domain,url) {
         // NOTE: we can't use AJAX if we want the user to get a save dialog
         window.location = '/portfolio?command=download&entity='+encodeURIComponent(entity)+
           '&domain='+encodeURIComponent(domain)+'&url='+url;
}

function editfile(entity,domain,url) {
    parent.display_editor('/portfolio?command=download&entity='+entity+'&domain='+domain+'&url='+url);
}


function init_datatable(destroy) {
   if (destroy) {
      parent.busy_block();
   }
   var noCache = parent.no_cache_value();
   $('#portfoliolist').dataTable( {
      "sAjaxSource" : '/portfolio?'+$('#portfolio').serialize()+'&command=listdirectory&showhidden='+showhidden+'&noCache='+noCache,
      "bAutoWidth": false, 
      "bDestroy"  : destroy,
      "bStateSave": true,
      "oLanguage" : {
         "sUrl" : "/datatable_i14n"
      },
      "fnInitComplete": function(oSettings, json) {
         $('#portfoliolist tr').click( function() {
                if ( $(this).hasClass('row_selected') ) {
                        $(this).removeClass('row_selected');
                } else {
                        $(this).addClass('row_selected');
                }
         } );
         if (destroy) {
            parent.busy_unblock();
         }
         adjust_framesize();
      },
      "aoColumns" : [
         { "bVisible": false },
         { "bSortable": false },
         {"iDataSort": 3},
         { "bVisible": false },
         null,
         null,
         null,
         {"bSortable":false },
         {"iDataSort": 9, "bVisible": false },
         {"bVisible": false },
         null,
         {"iDataSort": 12, "bVisible": false },
         { "bVisible": false },
         {"iDataSort": 14, "bVisible": false },
         { "bVisible": false },
         {"iDataSort": 16, "bVisible": false },
         { "bVisible": false }
      ]
    } );
}

function reload_listing() {
   init_datatable(true);
}

function load_path() {
   var noCache = parent.no_cache_value();
   var path='/';
   $.getJSON( '/portfolio', $('#portfolio').serialize()+"&command=listpath&noCache="+noCache , function( data ) {
       var newpath = "<ul id='pathrow' name='pathrow' class='lcpathrow'>";
       $.each(data,function(index,subdir) {
            $.each(subdir,function(key,value) {
               var disval=value;
               if (disval.length>15) {
                  disval=disval.substring(0,12)+" ...";
               }
               disval.replace("'","\\'");
               path+=key+'/';
               newpath+="<li class='lcpathitem'><a href='#' id='dir"+key+"' onClick='set_path(\""+path+"\")' title='"+value+"'>"+disval+"</a></li>";
            });
       });
       newpath+="</ul>";
       $("#newfile_path").val(path);
       $("#pathrow").replaceWith(newpath);
       adjust_framesize();
   });
}

function set_path(path) {
   $('#pathrow_path').val(path);
   reload_listing();
   load_path();
}

function fnShowHide( iCol ) {
   var oTable = $('#portfoliolist').dataTable();
   var bVis = oTable.fnSettings().aoColumns[iCol].bVisible;
   oTable.fnSetColumnVis( iCol, bVis ? false : true );
   adjust_framesize();
}

function select_filtered() {
   var oTable = $('#portfoliolist').dataTable();
   var aTrs = oTable.$('tr', {"filter":"applied"});
   for ( var i=0 ; i<aTrs.length ; i++ ) {
      $(aTrs[i]).addClass('row_selected');
   }
}

function select_all() {
   var oTable = $('#portfoliolist').dataTable();
   var aTrs = oTable.fnGetNodes();
   for ( var i=0 ; i<aTrs.length ; i++ ) {
      $(aTrs[i]).addClass('row_selected');
   }
}

function deselect_all() {
   var oTable = $('#portfoliolist').dataTable();
   var aTrs = oTable.fnGetNodes();
   for ( var i=0 ; i<aTrs.length ; i++ ) {
      $(aTrs[i]).removeClass('row_selected');
   }
}

function fnGetSelected() {
   var aReturn = new Array();
   var oTable = $('#portfoliolist').dataTable();
   var aTrs = oTable.fnGetNodes();	
   for ( var i=0 ; i<aTrs.length ; i++ ) {
      if ( $(aTrs[i]).hasClass('row_selected') ) {
	 aReturn.push(oTable.fnGetData(aTrs[i],0));
      }
   }
   if (aReturn.length>0) {
      return '['+aReturn.join(',')+']';
   } else {
      return '';
   }
}

function modify_selected() {
   var selectedUsers=fnGetSelected();
   if (selectedUsers=='') { return; }
   document.courseusers.postdata.value=selectedUsers;
   document.courseusers.method="post";
   document.courseusers.action="/pages/lc_modify_courselist.html";
   parent.setbreadcrumbbar('add','modifycourselist','Modify Selected Entries','');
   parent.breadcrumbbar();
   document.courseusers.submit();
}

function uploadsuccess(name) {
   $('.lcerror').hide();
   reload_listing();
}

function uploadfailure(name,code) {
    $('.lcerror').show();
}

