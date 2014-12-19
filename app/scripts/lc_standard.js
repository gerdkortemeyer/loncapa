var searchrepeat;

CKEDITOR.on('instanceReady', function(){
   if (window.parent.document) {
      adjust_framesize();
   }
});

window.addEventListener('load', function(e) {
        LCMATH.initEditors();
}, false);

function attach_submit_button(problemid,partid) {
   $('#'+partid+'_submit_button').click(function() {
       $('#'+partid+'_submit_button').hide();
       var data = $('#'+partid+'_form').serialize();
       $.ajax({
             data: data+"&outputid="+problemid,
             async: false,
             type:'POST',
             success: function(response) {
                 $('#'+problemid).replaceWith(response);
                 LCMATH.initEditors();
                 MathJax.Hub.Queue(["Typeset",MathJax.Hub]);
                 adjust_framesize();
             }
       });
   });
}

function attach_textfield_message(id,stat,msg) {
   $('#'+id).css('background-color','#FFFF66');
   $('#'+id).change(function(){
       $('#'+id).css('background-color','#FFFFFF');
   });
}

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

function lock_toggle(id) {
   if ($('#'+id+'_locked').val()==1) {
      $('#'+id+'_lock_img').attr('src','/images/lock_opened.png');
      $('#'+id).prop('disabled',false);
      $('#'+id+'_locked').val(0);
   } else {
      $('#'+id+'_lock_img').attr('src','/images/lock_closed.png');
      $('#'+id).prop('disabled',true);
      $('#'+id+'_locked').val(1);
   }
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

function setsearchusername(id,username) {
   if (username.length>0) {
      $('#'+id+'_resultdisplay').html(username);
   } else {
      $('#'+id+'_resultdisplay').html('---');
   }
   $("#"+id+"_username").val(username);
   if (typeof(section_update)=== "function") { 
      section_update(id);
   }
}

function coursesearch(id) {
   clearTimeout(searchrepeat);
   setsearchusername(id,$("#"+id+"_search").val());
   if ($("#"+id+"_search").val().length>0) {
      $.ajax({
             url: '/async?command=coursesearch&domain='+$("#"+id+"_domain").val()+'&term='+$("#"+id+"_search").val(),
             type:'GET'
             });
      coursesearchdisplay(id);
   } else {
      $('#'+id+'_results').css('height','0px');
      $('#'+id+'_results').css('visibility','hidden');
   }
}

function usersearch(id) {
   clearTimeout(searchrepeat);
   setsearchusername(id,$("#"+id+"_search").val());
   if ($("#"+id+"_search").val().length>0) {
      $.ajax({
             url: '/async?command=usersearch&domain='+$("#"+id+"_domain").val()+'&term='+$("#"+id+"_search").val(),
             type:'GET'
             });
      usersearchdisplay(id);
   } else {
      $('#'+id+'_results').css('height','0px');
      $('#'+id+'_results').css('visibility','hidden');
   }
}

function userautocompleteselect(id,username,firstname,lastname) {
   setsearchusername(id,unescape(username));
   $('#'+id+'_search').val(unescape(firstname)+' '+unescape(lastname));
}

function courseautocompleteselect(id,courseid,title) {
   setsearchusername(id,unescape(courseid));
   $('#'+id+'_search').val(unescape(title));
}


function usersearchdisplay(id) {
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
                         var firstname='';
                         var middlename='';
                         var lastname='';
                         var suffix='';
                         var username='';
                         $.each(subsubval, function ( subsubsubkey,subsubsubval ) {
                             if (subsubsubkey=='firstname')  { firstname=subsubsubval; }
                             if (subsubsubkey=='middlename') { middlename=subsubsubval; }
                             if (subsubsubkey=='lastname')   { lastname=subsubsubval; }
                             if (subsubsubkey=='username')   { username=subsubsubval; }
                         });
                         content+='<li class="lcautocompleteentry"><a href="#" class="lcautocompleteselect" onclick="userautocompleteselect(\''
                                 +escape(id)+"','"+escape(username)+"','"+escape(firstname)+"','"+escape(lastname)+'\')">';
                         content+=firstname+' '+middlename+' '+lastname+' '+suffix;
                         content+='</a></li>';
                      });
                  });
               }
           });
           content+='</ul>';
           $('#'+id+'_results').html(content);
           $('#'+id+'_results').css('height','200px');
           $('#'+id+'_results').css('visibility','visible');
           adjust_framesize();
           searchrepeat=setTimeout(usersearchdisplay,1000,id);
       });
   }
}

function coursesearchdisplay(id) {
   if ($("#"+id+"_search").val().length>0) {
      var noCache = parent.no_cache_value();
      $.getJSON( "/asyncresults", { "noCache": noCache,
                                 "domain" : $("#"+id+"_domain").val(),
                                 "term"   : $("#"+id+"_search").val(),
                                 "command" : "coursesearch" },
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
                         var title='';
                         var courseid='';
                         $.each(subsubval, function ( subsubsubkey,subsubsubval ) {
                             if (subsubsubkey=='courseid')  { courseid=subsubsubval; }
                             if (subsubsubkey=='title') { title=subsubsubval; }
                         });
                         content+='<li class="lcautocompleteentry"><a href="#" class="lcautocompleteselect" onclick="courseautocompleteselect(\''
                                 +escape(id)+"','"+escape(courseid)+"','"+escape(title)+'\')">';
                         content+=title+" ("+courseid+")";
                         content+='</a></li>';
                      });
                  });
               }
           });
           content+='</ul>';
           $('#'+id+'_results').html(content);
           $('#'+id+'_results').css('height','200px');
           $('#'+id+'_results').css('visibility','visible');
           adjust_framesize();
           searchrepeat=setTimeout(coursesearchdisplay,1000,id);
       });
   }
}

function loadtaxo(id,which,first,second,preselect) {
   var noCache = parent.no_cache_value();
   $.getJSON( "/publisher", { "noCache" : noCache,
                              "level"   : which,
                              "first"   : first,
                              "second"  : second,
                              "command" : "taxonomy" },
       function( data ) {
           var content='';
           $.each( data, function( index, val ) {
               $.each( val, function( key, value ) {
                    content+="<option value='"+key+"'>"+value+"</option>";
               });
           });
           $('#'+id+'_'+which).html(content);
           if (preselect) {
              $('#'+id+'_'+which).val(preselect);
           }
       });

}

function taxoselect(id,which) {
   var firstselected=$('#'+id+'_first').val();
   var secondselected=$('#'+id+'_second').val();
   var thirdselected=$('#'+id+'_third').val();
   if (which=="all") {
      loadtaxo(id,'first',firstselected,secondselected,firstselected);
      loadtaxo(id,'second',firstselected,secondselected,secondselected);
      loadtaxo(id,'third',firstselected,secondselected,thirdselected);
   }
   if (which=="first") {
      loadtaxo(id,'second',firstselected,secondselected);
      loadtaxo(id,'third',firstselected,secondselected);
   }
   if (which=="second") {
      loadtaxo(id,'third',firstselected,secondselected);
   }
}


