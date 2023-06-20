ahoy.configure({
    trackVisits: false // Disable automatic client-side visit tracking
});

var Tracking = {
    init: function () {
        $('[data-trackable]').click(Tracking.track);
    },

    /**
     * Function that registers a click on an outbound link in Analytics.
     * This function takes a valid URL string as an argument, and uses that URL string
     * as the event label. Setting the transport method to 'beacon' lets the hit be sent
     * using 'navigator.sendBeacon' in browser that support it.
     */
    track: function () {
        if (this.dataset.trackableType && this.dataset.trackableId) {
            ahoy.track('Visited Link', {
                url: this.href,
                trackable_type: this.dataset.trackableType,
                trackable_id: parseInt(this.dataset.trackableId)
            });
        }
        if (window.gtag) {
            gtag('event', 'click', {
                'event_category': 'outbound',
                'event_label': url,
                'transport_type': 'beacon',
                'event_callback': function() {} // Not needed
            });
        }
        return true;
    }
}
