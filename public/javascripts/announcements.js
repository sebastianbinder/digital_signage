$(document).ready(function() {
 $('dd.show_at input[type=text]').datepicker({dateFormat: "MM d, yy '12:00 AM'"});
 var announcement = $('dd.announcement textarea');
 if(announcement.length) { announcement.wysiwyg({css: ROOT_URL+'stylesheets/wysiwyg.css'}); }
});