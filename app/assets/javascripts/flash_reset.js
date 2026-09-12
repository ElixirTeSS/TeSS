// Clears flash alerts on Turbolinks / Turbo navigation so they don't persist
// between visits or when navigating via back/forward cache.
(function() {
  function clearFlash() {
    var container = document.getElementById('flash-container');
    if (container) {
      container.innerHTML = '';
    }
  }

  function removeFlashAlertsBeforeCache() {
    document.querySelectorAll('#flash-container .alert').forEach(function(el) { el.remove(); });
  }

  if (typeof document !== 'undefined') {
    document.addEventListener('turbolinks:before-visit', clearFlash);
    document.addEventListener('turbolinks:before-cache', removeFlashAlertsBeforeCache);

    document.addEventListener('turbo:before-visit', clearFlash);
    document.addEventListener('turbo:before-cache', removeFlashAlertsBeforeCache);
    
    function handleLoad() {
      try {
        var lastHost = sessionStorage.getItem('tess_last_host');
        var refHost = document.referrer ? (new URL(document.referrer)).host : null;
        var currentHost = window.location.host;

        // If we have seen a different host previously (via sessionStorage) or
        // the referrer host differs from current host, clear flashes.
        if ((lastHost && lastHost !== currentHost) || (refHost && refHost !== currentHost)) {
          clearFlash();
        }

        // Remember current host for next navigations (works across turbolinks visits)
        sessionStorage.setItem('tess_last_host', currentHost);
      } catch (e) {
        // Ignore any URL parsing/sessionStorage errors
      }
    }

    document.addEventListener('turbolinks:load', handleLoad);
    document.addEventListener('turbo:load', handleLoad);
    document.addEventListener('DOMContentLoaded', handleLoad);
  }
})();

