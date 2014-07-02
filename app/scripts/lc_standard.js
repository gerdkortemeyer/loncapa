var searchrepeat;

CKEDITOR.on('instanceReady', function(){
   if (window.parent.document) {
      adjust_framesize();
   }
});

window.addEventListener('load', function(e) {
        LCMATH.initEditors();
}, false);

function adjust_framesize() {
      var frameheight=document.body.offsetHeight + 50;
      $("#contentframe",window.parent.document).css({ height : frameheight + 'px' });
}

function screendefaults(formname,storename) {
   var data = $('#'+formname).serialize();
   $.ajax({
             url: '/screendefaults/'+storename,
             data: data,
             async: false,
             type:'POST'
          });
}

function progressbar(id,process) {
   var noCache = parent.no_cache_value();
   $.getJSON( "/progress/"+process, { "noCache": noCache }, function( data ) {
      var total=1;
      var success=0;
      var skip=0;
      var fail=0;
      $.each( data, function( key, val ) {
         if (key=='total') { total=val; }
         if (key=='success') { success=val; }
         if (key=='skip') { skip=val; }
         if (key=='fail') { fail=val; }
      });
      var percsuccess=0;
      var percskip=0;
      var percfail=0;
      if (total>0) {
         percsuccess=100*success/total;
         percskip=100*skip/total;
         percfail=100*fail/total;
      }
      $('#lcprogresssuccess').css('width',percsuccess+'%');
      $('#lcprogressskip').css('width',percskip+'%');
      $('#lcprogressfail').css('width',percfail+'%');
      setTimeout(progressbar,1000,id,process);
   });
}

function usersearch(id) {
   clearTimeout(searchrepeat);
   if ($("#"+id+"_search").val().length>0) {
      $.ajax({
             url: '/async?command=usersearch&domain='+$("#"+id+"_domain").val()+'&term='+$("#"+id+"_search").val(),
             type:'GET'
             });
      searchdisplay(id);
   } else {
      $('#'+id+'_results').css('height','0px');
      $('#'+id+'_results').css('visibility','hidden');
   }
}

function searchdisplay(id) {
   if ($("#"+id+"_search").val().length>0) {
      var noCache = parent.no_cache_value();
      $.getJSON( "/asyncresults", { "noCache": noCache, 
                                 "domain" : $("#"+id+"_domain").val(), 
                                 "term"   : $("#"+id+"_search").val(), 
                                 "command" : "usersearch" }, 
       function( data ) {
           var content='<ul>';
           $.each( data, function( key, val ) {
               if (key=='count') {
                  if (val<100) {
                     content+='<li class="lcautocompletecount">'+val+'</li>';
                  } else {
                     content+='<li class="lcautocompletecount">&gt;100</li>';
                  }
               }
               if ((key=='records') && (typeof(val)=='object'))  {
                  $.each(val, function( domain, subval ) {
                      $.each(subval, function( entity, subsubval ) {
                         content+='<li class="lcautocompleteentry">'+entity+':'+domain+': ';
                         $.each(subsubval, function ( subsubsubkey,subsubsubval ) {
                             content+=' '+subsubsubkey+" = "+subsubsubval+' ';
                         });
                         content+='</li>';
                      });
                  });
               }
           });
           content+='</ul>';
           $('#'+id+'_results').html(content);
           $('#'+id+'_results').css('height','200px');
           $('#'+id+'_results').css('visibility','visible');
           adjust_framesize();
           searchrepeat=setTimeout(searchdisplay,1000,id);
       });
   }
}

