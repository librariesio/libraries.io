(function() {
  if (!amplitudeEnabledForRequest) return

  amplitude.init(amplitudeApiKey, padUserId(currentUserId))

  const identifyEvent = new amplitude.Identify()
  identifyEvent.set("id", currentUserId)
  identifyEvent.set("email", currentUserEmail)
  amplitude.identify(identifyEvent)

  document.addEventListener("turbolinks:load", function() {
    $("a").on("click", function() {
      // track any external links
      if (isExternalLink(this)) {
        url = $(this).attr("href")
        logMetrics("Outbound Link", { url: url })
      }
    })
  })

  window.addEventListener("pagehide", () => {
    // If the page is unloading, we need to use the `sendBeacon` API
    amplitude.setTransport("beacon")
    amplitude.flush()
  })

  function isExternalLink(element) {
    return window.location.hostname !== element.hostname
  }

  function logMetrics(eventType, eventProperties) {
    amplitude.track(eventType, eventProperties)
  }

  // The User IDs stored on Amplitude are at least 6 characters long and are
  // padded with 0s if needed.
  function padUserId(userId) {
    if (!userId) return null

    return String(userId).padStart(6, "0")
  }
})();
