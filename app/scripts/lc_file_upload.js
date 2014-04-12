function do_upload (form,event,id) {
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
   xhr.open('post','/upload_file', true);
   xhr.onload = function () {
      if (xhr.status === 200) {
          $('#'+id+'label').html(oldtext);
       } else { 
          $('#'+id+'label').html(file.name+': ---');
       }
   };
   xhr.send(formdata);
}
