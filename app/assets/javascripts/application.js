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
//= require jquery_ujs
//= require bootstrap/alert
//= require bootstrap/collapse
//= require bootstrap/dropdown
//= require bootstrap/transition
//= require bootstrap/tab
//= require bootstrap/tooltip
//= require rails-timeago
//= require subtome
//= require turbolinks
//= require autotrack

document.addEventListener('turbolinks:load', function(){
  $('.tip').tooltip({placement: 'bottom'})
  stickFooter()

  // ga autotrack config
  ga('require', 'linkid');
  ga('require', 'eventTracker');
  ga('require', 'outboundLinkTracker');
  ga('require', 'impressionTracker', {
    elements: $('[data-ga-tracked-el]').map(function() {
      return $(this).data('ga-tracked-el');
    }).get()
  });
  ga('require', 'maxScrollTracker', {
    maxScrollMetricIndex: 1,
  });
  ga('require', 'mediaQueryTracker', {
    definitions: [
      {
        name: 'Breakpoint',
        dimensionIndex: 1,
        items: [
          {name: 'sm', media: 'all'},
          {name: 'md', media: '(min-width: 768px)'},
          {name: 'lg', media: '(min-width: 1200px)'}
        ]
      },
      {
        name: 'Pixel Density',
        dimensionIndex: 2,
        items: [
          {name: '1x',   media: 'all'},
          {name: '1.5x', media: '(min-resolution: 144dpi)'},
          {name: '2x',   media: '(min-resolution: 192dpi)'}
        ]
      },
      {
        name: 'Orientation',
        dimensionIndex: 3,
        items: [
          {name: 'landscape', media: '(orientation: landscape)'},
          {name: 'portrait',  media: '(orientation: portrait)'}
        ]
      }
    ]
  });
  ga('require', 'pageVisibilityTracker', {
    visibleMetricIndex: 2,
  });

  load_async('#version_dependencies');
  load_async('#top_dependent_projects');
  load_async('#top_dependent_repos');
  load_async('#repository_dependencies');

  $('.rss').on('click', function(){
    subtome($(this).attr('href'))
    return false;
  })

  $('input[name="subscription[include_prerelease]"]').on('change',function(){
    console.log('chanage')
    $(this).parents('form').submit();
  });
})

function load_async(id) {
  if($(id).length && $(id).data('url').length){
    $.get($(id).data('url'), function(data) {
      $(id).html(data).toggle(data.length > 0);
      stickFooter()
    });
  }
}

$(document).ready(stickFooter);

$(window).on('resize', stickFooter);

function stickFooter() {
  if ($(document).height() <= $(window).height()) {
      $('footer').addClass("navbar-fixed-bottom");
  } else {
      $('footer').removeClass("navbar-fixed-bottom");
  }
}
