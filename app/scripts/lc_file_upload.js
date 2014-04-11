function do_upload (form,event,url) {
   event.preventDefault();
   var file = form.fileselect.files[0];
   var formdata = new FormData();
   formdata.append('uploads', file, file.name);
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
