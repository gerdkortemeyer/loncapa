function do_upload (form,event,url) {
   event.preventDefault();
   var files = form.fileselect.files;
   var formdata = new FormData();
   for (var i = 0; i < files.length; i++) {
       var file = files[i];
       formdata.append('uploads', file, file.name);
   }
   var xhr = new XMLHttpRequest();
   xhr.open('post', url, true);
   xhr.onload = function () {
      if (xhr.status === 200) {
          alert("Done!");
       } else { 
          alert('An error occurred!');
       }
   };
   xhr.send(formdata);
}
