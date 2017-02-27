/*!
 * @preserve
 * gascrolldepth.js | v0.9
 * Copyright (c) 2015 Rob Flaherty (@robflaherty), Leigh McCulloch (@___leigh___)
 * Licensed under the MIT and GPL licenses.
 */
;(function ( window, document, undefined ) {

  "use strict";

  /*
   * Extend a series of objects with the properties of each.
   * Ref: http://stackoverflow.com/a/11197343/159762
   */

  function extend(){
    for ( var i=1; i<arguments.length; i++ )
      for ( var key in arguments[i] )
        if ( arguments[i].hasOwnProperty(key) )
          arguments[0][key] = arguments[i][key];
    return arguments[0];
  }

  /*
   * Returns true if the element is in the array. Exact comparison is used.
   */

  function inArray(array, element) {
    for ( var i=0; i<array.length; i++ )
      if ( array[i] === element )
        return true;
    return false;
  }

  /*
   * Returns true if the object is an array.
   */
  function isArray(object) {
    return Object.prototype.toString.call(object) === '[object Array]';
  }

  /*
   * Reliably get the document height.
   * Borrowed from:
   * jQuery
   * https://jquery.org/
   * Ref: https://github.com/jquery/jquery/blob/a644101ed04d0beacea864ce805e0c4f86ba1cd1/src/dimensions.js#L33
   * Copyright: jQuery Foundation and other contributors
   * License: https://github.com/jquery/jquery/blob/a644101ed04d0beacea864ce805e0c4f86ba1cd1/LICENSE.txt
   */

  function getDocumentHeight() {
    return Math.max(
      document.documentElement["scrollHeight"], document.body["scrollHeight"],
      document.documentElement["offsetHeight"], document.body["offsetHeight"],
      document.documentElement["clientHeight"]
    );
  }

  /*
   * Reliably get the window height.
   * Ref: http://www.w3schools.com/js/js_window.asp
   */

  function getWindowHeight() {
    return window.innerHeight || document.documentElement.clientHeight || document.body.clientHeight;
  }

  /*
   * Reliably get the page y-axis offset due to scrolling.
   * Ref: https://developer.mozilla.org/en-US/docs/Web/API/Window/scrollY
   */

  function getPageYOffset() {
    return window.pageYOffset || (document.compatMode === "CSS1Compat" ? document.documentElement.scrollTop : document.body.scrollTop);
  }

  /*
   * Reliably get the element's y-axis offset to the document top.
   * Ref: https://developer.mozilla.org/en-US/docs/Web/API/Element/getBoundingClientRect
   */

  function getElementYOffsetToDocumentTop(element) {
    return element.getBoundingClientRect().top + getPageYOffset();
  }

  /*
   * Try really hard to get the first element matching a selector.
   * Aims to support all browsers at least for selectors starting with `#`.
   */

  function getElementBySelector(selector) {
    if (typeof window['jQuery'] !== 'undefined') {
      return window['jQuery'](selector).get(0);
    } else if (typeof document.querySelector !== 'undefined') {
      return document.querySelector(selector);
    } else if (selector.charAt(0) == '#') {
      return document.getElementById(selector.substr(1));
    }
    return undefined;
  }

  /*
   * Register and Deregister for `eventName` on `element`.
   * Aims to support all browsers.
   */

  function addEventListener(element, eventName, handler) {
    if ( element.addEventListener ) {
      element.addEventListener(eventName, handler, false);
    } else if ( element.attachEvent )  {
      element.attachEvent('on' + eventName, handler);
    } else {
      element['on' + eventName] = handler;
    }
  }

  function removeEventListener(element, eventName, handler) {
    if ( element.removeEventListener ) {
      element.removeEventListener(eventName, handler, false);
    } else if ( element.detachEvent ) {
      element.detachEvent('on' + eventName, handler);
    } else {
      element['on' + type] = null;
    }
  }

  /*
   * Module variables.
   */
  var defaults = {
    minHeight: 0,
    elements: [],
    percentage: true,
    userTiming: true,
    pixelDepth: true,
    nonInteraction: true,
    gaGlobal: false,
    gtmOverride: false
  };

  var options = extend({}, defaults),
    cache = [],
    scrollEventBound = false,
    lastPixelDepth = 0,
    universalGA,
    classicGA,
    gaGlobal,
    standardEventHandler,
    scrollEventHandler;

  /*
   * Bind and unbind the scroll event handler.
   */

  function bindScrollDepth(scrollEventHandler) {
    scrollEventBound = true;
    addEventListener(window, 'scroll', scrollEventHandler);
  }

  function unbindScrollDepth(scrollEventHandler) {
    scrollEventBound = false;
    removeEventListener(window, 'scroll', scrollEventHandler);
  }

  /*
   * Library Interface
   */

  // Initialize the library.
  var init = function(initOptions) {

    var startTime = +new Date;

    options = extend({}, defaults, initOptions);

    // Return early if document height is too small
    if ( getDocumentHeight() < options.minHeight ) {
      return;
    }

    /*
     * Determine which version of GA is being used
     * "ga", "__gaTracker", _gaq", and "dataLayer" are the possible globals
     */

    if (options.gaGlobal) {
      universalGA = true;
      gaGlobal = options.gaGlobal;
    } else if (typeof ga === "function") {
      universalGA = true;
      gaGlobal = 'ga';
    } else if (typeof __gaTracker === "function") {
      universalGA = true;
      gaGlobal = '__gaTracker';
    }

    if (typeof _gaq !== "undefined" && typeof _gaq.push === "function") {
      classicGA = true;
    }

    if (typeof options.eventHandler === "function") {
      standardEventHandler = options.eventHandler;
    } else if (typeof dataLayer !== "undefined" && typeof dataLayer.push === "function" && !options.gtmOverride) {

      standardEventHandler = function(data) {
        dataLayer.push(data);
      };
    }

    /*
     * Functions
     */

    function sendEvent(action, label, scrollDistance, timing) {

      if (standardEventHandler) {

        standardEventHandler({'event': 'ScrollDistance', 'eventCategory': 'Scroll Depth', 'eventAction': action, 'eventLabel': label, 'eventValue': 1, 'eventNonInteraction': options.nonInteraction});

        if (options.pixelDepth && arguments.length > 2 && scrollDistance > lastPixelDepth) {
          lastPixelDepth = scrollDistance;
          standardEventHandler({'event': 'ScrollDistance', 'eventCategory': 'Scroll Depth', 'eventAction': 'Pixel Depth', 'eventLabel': rounded(scrollDistance), 'eventValue': 1, 'eventNonInteraction': options.nonInteraction});
        }

        if (options.userTiming && arguments.length > 3) {
          standardEventHandler({'event': 'ScrollTiming', 'eventCategory': 'Scroll Depth', 'eventAction': action, 'eventLabel': label, 'eventTiming': timing});
        }

      } else {

        if (universalGA) {

          window[gaGlobal]('send', 'event', 'Scroll Depth', action, label, 1, {'nonInteraction': options.nonInteraction});

          if (options.pixelDepth && arguments.length > 2 && scrollDistance > lastPixelDepth) {
            lastPixelDepth = scrollDistance;
            window[gaGlobal]('send', 'event', 'Scroll Depth', 'Pixel Depth', rounded(scrollDistance), 1, {'nonInteraction': options.nonInteraction});
          }

          if (options.userTiming && arguments.length > 3) {
            window[gaGlobal]('send', 'timing', 'Scroll Depth', action, timing, label);
          }

        }

        if (classicGA) {

          _gaq.push(['_trackEvent', 'Scroll Depth', action, label, 1, options.nonInteraction]);

          if (options.pixelDepth && arguments.length > 2 && scrollDistance > lastPixelDepth) {
            lastPixelDepth = scrollDistance;
            _gaq.push(['_trackEvent', 'Scroll Depth', 'Pixel Depth', rounded(scrollDistance), 1, options.nonInteraction]);
          }

          if (options.userTiming && arguments.length > 3) {
            _gaq.push(['_trackTiming', 'Scroll Depth', action, timing, label, 100]);
          }

        }

      }

    }

    function calculateMarks(docHeight) {
      return {
        '25%' : parseInt(docHeight * 0.25, 10),
        '50%' : parseInt(docHeight * 0.50, 10),
        '75%' : parseInt(docHeight * 0.75, 10),
        // Cushion to trigger 100% event in iOS
        '100%': docHeight - 5
      };
    }

    function checkMarks(marks, scrollDistance, timing) {
      // Check each active mark
      for ( var key in marks ) {
        if ( !marks.hasOwnProperty(key) )
          continue;
        var val = marks[key];
        if ( !inArray(cache, key) && scrollDistance >= val ) {
          sendEvent('Percentage', key, scrollDistance, timing);
          cache.push(key);
        }
      }
    }

    function checkElements(elements, scrollDistance, timing) {
      for ( var i=0; i<elements.length; i++) {
        var elem = elements[i];
        if ( !inArray(cache, elem) ) {
          var elemNode = (typeof elem === "string") ? getElementBySelector(elem) : elem;
          if ( elemNode ) {
            var elemYOffset = getElementYOffsetToDocumentTop(elemNode);
            if ( scrollDistance >= elemYOffset ) {
              sendEvent('Elements', elem, scrollDistance, timing);
              cache.push(elem);
            }
          }
        }
      };
    }

    function rounded(scrollDistance) {
      // Returns String
      return (Math.floor(scrollDistance/250) * 250).toString();
    }

    /*
     * Throttle function borrowed from:
     * Underscore.js 1.5.2
     * http://underscorejs.org
     * (c) 2009-2013 Jeremy Ashkenas, DocumentCloud and Investigative Reporters & Editors
     * Underscore may be freely distributed under the MIT license.
     */

    function throttle(func, wait) {
      var context, args, result;
      var timeout = null;
      var previous = 0;
      var later = function() {
        previous = new Date;
        timeout = null;
        result = func.apply(context, args);
      };
      return function() {
        var now = new Date;
        if (!previous) previous = now;
        var remaining = wait - (now - previous);
        context = this;
        args = arguments;
        if (remaining <= 0) {
          clearTimeout(timeout);
          timeout = null;
          previous = now;
          result = func.apply(context, args);
        } else if (!timeout) {
          timeout = setTimeout(later, remaining);
        }
        return result;
      };
    }

    /*
     * Scroll Event
     */

    scrollEventHandler = throttle(function() {
      /*
       * We calculate document and window height on each scroll event to
       * account for dynamic DOM changes.
       */

      var docHeight = getDocumentHeight(),
        winHeight = getWindowHeight(),
        scrollDistance = getPageYOffset() + winHeight,

        // Recalculate percentage marks
        marks = calculateMarks(docHeight),

        // Timing
        timing = +new Date - startTime;

      // If all marks already hit, unbind scroll event
      if (cache.length >= 4 + options.elements.length) {
        unbindScrollDepth();
        return;
      }

      // Check specified DOM elements
      if (options.elements) {
        checkElements(options.elements, scrollDistance, timing);
      }

      // Check standard marks
      if (options.percentage) {
        checkMarks(marks, scrollDistance, timing);
      }
    }, 500);

    bindScrollDepth(scrollEventHandler);
  };

  // Reset Scroll Depth with the originally initialized options
  var reset = function() {
    cache = [];
    lastPixelDepth = 0;

    if (typeof scrollEventHandler == "undefined") {
      return;
    }

    unbindScrollDepth(scrollEventHandler);
    bindScrollDepth(scrollEventHandler);
  };

  // Add DOM elements to be tracked
  var addElements = function(elems) {
    if (typeof elems == "undefined" || !isArray(elems)) {
      return;
    }

    for (var i=0; i<elems.length; i++) {
      var elem = elems[i];
      var elemIndex = options.elements.indexOf(elem);
      if (elemIndex == -1) {
        options.elements.push(elem);
      }
    }

    if (!scrollEventBound) {
      bindScrollDepth();
    }
  };

  // Remove DOM elements currently tracked
  var removeElements = function(elems) {
    if (typeof elems == "undefined" || !isArray(elems)) {
      return;
    }

    for (var i=0; i<elems.length; i++) {
      var elem = elems[i];

      var elementsIndex = options.elements.indexOf(elem);
      if (elementsIndex > -1) {
        options.elements.splice(elementsIndex, 1);
      }

      var cacheIndex = cache.indexOf(elem);
      if (cacheIndex > -1) {
        cache.splice(cacheIndex, 1);
      }
    }
  };

  /*
   * Globals
   */

  window.gascrolldepth = {
    init: init,
    reset: reset,
    addElements: addElements,
    removeElements: removeElements
  };

  /*
   * jQuery Plugin
   */

  if ( typeof window['jQuery'] !== 'undefined' ) {
    window['jQuery'].gascrolldepth = init;
  }

})( window, document );