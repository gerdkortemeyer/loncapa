function do_upload (form,event,url,id,success,fail) {
   event.preventDefault();
   var file = form.elements[id].files[0];
   var oldtext=$('#'+id+'label').html();
   $('#'+id+'label').html(file.name+' ...');
   var formdata = new FormData();
   formdata.append('uploads', file, file.name);
   var xhr = new XMLHttpRequest();
   xhr.upload.addEventListener("progress", function(e) {
      if (e.lengthComputable) {
         var percentComplete = Math.round(100*e.loaded / e.total);
         $('#'+id+'label').html(file.name+': '+percentComplete+'%');
      } else {
         $('#'+id+'label').html(file.name+': '+e.loaded);
      }
   }, false);
   xhr.open('post',url, true);
   xhr.onload = function () {
      $('#'+id+'label').html(oldtext);
      if (xhr.status === 200) {
          var fn=window[success];
          if (typeof(fn)==='function') {
             fn(file.name);
          }
       } else { 
          var fn=window[fail];
          if (typeof(fn)==='function') {
             fn(file.name,xhr.status);
          } else {
             alert("Error "+xhr.status+" uploading "+file.name);
          }
       }
   };
   xhr.send(formdata);
}
