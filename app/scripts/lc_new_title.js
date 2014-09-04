var entity;
var domain;
var title;

$(document).ready(function() {
     entity=parent.getParameterByName(location.search,'entity');
     domain=parent.getParameterByName(location.search,'domain');
     url=parent.getParameterByName(location.search,'url');
     title=parent.getParameterByName(location.search,'title');
     $('#newtitle').val(title);
     $('#storebutton').click(function() {
         $.ajax({
             url: '/portfolio',
             type:'POST',
             data: { 'command' : 'changetitle',
                     'entity'  : entity,
                     'domain'  : domain,
                     'url'     : url,
                     'title'   : $('#newtitle').val() },
             success: function(response) {
                if (response=='error') {
                   $('.lcstandard').hide();
                   $('.lcerror').show();
                } else {
                   parent.frames['contentframe'].contentWindow.reload_listing();
                   parent.hide_modal();
                }
             },
             error: function(xhr, ajaxOptions, errorThrown) {
                $('.lcstandard').hide();
                $('.lcerror').show();
             }
         });         
     });
     $('#cancelbutton').click(function() {
        parent.hide_modal();
     });
});
