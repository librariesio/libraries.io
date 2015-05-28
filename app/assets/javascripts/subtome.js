var subtome = function(url) {
  var feeds = [], resource = window.location.toString();

  feeds.push(encodeURIComponent(url));

  var src = 'https://www.subtome.com';
  var parentUrl = (window.location != window.parent.location) ? document.referrer: document.location;
  var s = document.createElement('iframe');
  src += '/?subs'; // Fix for Firefox with messes things up! Thanks Yvo for the precious tip!
  src += '/#/subscribe?resource=' + encodeURIComponent(resource) + '&feeds=' + encodeURIComponent(feeds.join(','));

  s.setAttribute('style','display:block; position:fixed; top:0px; left:0px; width:100%; height:100%; border:0px; background: transparent; z-index: 2147483647');
  s.setAttribute('src', src);
  var loaded = false;
  s.onload = function() {
    if(loaded) {
      document.getElementsByTagName('body')[0].removeChild(s);
    }
    loaded = true;
  }
  document.getElementsByTagName('body')[0].appendChild(s);
  window.addEventListener("message", function(event) {
    if (event.origin !== "https://www.subtome.com")
      return;

    var _gaq = window._gaq || [];
    _gaq.push(['_trackEvent', 'subtome', 'follow', event.data.subscription.app.name]);
  });
}
