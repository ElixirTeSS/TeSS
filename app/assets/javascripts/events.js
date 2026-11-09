var Events = {
    switchCostFields: function () {
        var el = $('.event_cost_basis option:selected');
        if (el.length) {
            var option = el.val();
            //alert('selected = ' + option)
            if (!option || option === 'free' || option === '') {
                $('.event_cost_currency').hide()
                $('.event_cost_value').hide()
                $('#event_cost_currency').val("")
                $('#event_cost_value').val("")
            } else {
                $('.event_cost_currency').show()
                $('.event_cost_value').show()
            }
        }
    },

    switchAddressFields: function () {
        var el = $('[data-role="online-switch"]:checked');
        if (el.length) {
            var option = el.val();
            if (option === 'true') {
                $('.address_content').hide()
            } else {
                $('.address_content').show()
            }
        }
    },

    // Whether the city, country or postcode were edited by hand since the coordinates were set by the address finder
    coordinatesStale: false,
    timezoneRequest: null,

    // Show the time zone of the event's location if none is selected, or if it differs from the selected one.
    // This is only advice: the user can keep their own choice.
    suggestTimezone: function () {
        var box = $('#timezone-suggestion');
        if (!box.length) {
            return;
        }
        var params = { timezone: $('#event_timezone').val(), country: $('#event_country').val() };
        if (!Events.coordinatesStale) {
            params.latitude = $('#event_latitude').val();
            params.longitude = $('#event_longitude').val();
        }
        if (Events.timezoneRequest) {
            Events.timezoneRequest.abort();
        }
        Events.timezoneRequest = $.getJSON(box.data('url'), params, function (data) {
            if (data.message) {
                box.find('[data-role="timezone-suggestion-message"]').text(data.message);
                box.find('[data-role="timezone-suggestion-use"]').text(data.button).data('timezone', data.timezone);
                box.show();
            } else {
                box.hide();
            }
        });
    }
}

$(document).on('change', '[data-role="online-switch"]', function () {
    Events.switchAddressFields();
});

$(document).on('change', '.event_cost_basis', function () {
    Events.switchCostFields();
});

$(document).on('change', '#event_timezone, [data-role="online-switch"]', function () {
    Events.suggestTimezone();
});

// The address finder sets the coordinates (and triggers this change) together with the address fields
$(document).on('change', '#event_latitude', function () {
    Events.coordinatesStale = false;
    Events.suggestTimezone();
});

$(document).on('change', '#event_city, #event_country, #event_postcode', function () {
    Events.coordinatesStale = true;
    Events.suggestTimezone();
});

$(document).on('click', '[data-role="timezone-suggestion-use"]', function () {
    $('#event_timezone').val($(this).data('timezone')).trigger('change');
});

$(document).on('ready turbolinks:load', function () {
    Events.switchCostFields();
    Events.switchAddressFields();
    Events.coordinatesStale = false;
    Events.suggestTimezone();
});
