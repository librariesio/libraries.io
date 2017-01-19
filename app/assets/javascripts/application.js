// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require payola
//= require jquery_ujs
//= require bootstrap/alert
//= require bootstrap/collapse
//= require bootstrap/dropdown
//= require bootstrap/transition
//= require bootstrap/tab
//= require bootstrap/tooltip
//= require js.cookie
//= require rails-timeago
//= require subtome
//= require turbolinks

document.addEventListener('turbolinks:load', function(){
  $('.tip').tooltip({placement: 'bottom'})
  stickFooter()
})

$('.rss').on('click', function(){
  subtome($(this).attr('href'))
  return false;
})

$('.learn-more').on('click', function(){
  $('#welcome-alert').alert('close')
})

$('#welcome-alert').on('closed.bs.alert', function() {
  Cookies.set('hide_welcome_alert', 'true');
});

$('input[name="subscription[include_prerelease]"]').on('change',function(){
  $(this).parents('form').submit();
});

$(window).on('resize', stickFooter);

function stickFooter() {
  if ($(document).height() <= $(window).height()) {
      $('footer').addClass("navbar-fixed-bottom");
  } else {
      $('footer').removeClass("navbar-fixed-bottom");
  }
}
