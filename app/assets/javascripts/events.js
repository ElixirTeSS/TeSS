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
    }
}

function updateDateTimes(render_controls = false) {
    // Assemble the data parameters for the query string
    var event_ids = $.map($('.time-with-zone'), function(div) {
        return $(div).data('event-id')
    })
    var timezone = $('input[type=radio][name=timezone-choice]:checked').val();
    var data = { event_ids: event_ids,
                 tz: timezone}
    if (render_controls) {
        data['browser_timezone'] = Intl.DateTimeFormat().resolvedOptions().timeZone;
    }

    // Server renders the various DOM ids that need updating
    $.ajax({
        url: "/events/event_time_data.json",
        data: data,
        context: document.body
    }).done(function(elements) {
        // Replace content of server-rendered ids with new content
        elements.forEach(function(element) {
            $(element['id']).replaceWith(element['html'])
        })

        if (render_controls) {
            // This is just run on initial page load, set up controls
            // (controls aren't rendered on page initially served)
            $('#timezone-controls .close-timezone-controls').click(function() {
              $('#timezone-select').collapse('hide')
              $('#timezone-controls .show-timezone-controls').show();
            });
            $('#timezone-controls .show-timezone-controls').click(function() {
              $(this).hide();
            });
            $('input[type=radio][name=timezone-choice]').change(function() {
                updateDateTimes();
                $('.timezone-display-value').toggleClass('unselected')
            })
        }
    });

}

$(document).on('change', '[data-role="online-switch"]', function () {
    Events.switchAddressFields();
});

$(document).on('change', '.event_cost_basis', function () {
    Events.switchCostFields();
});

$(document).on('ready turbolinks:load', function () {
    Events.switchCostFields();
    Events.switchAddressFields();
    if ($('.time-with-zone').length) {
        updateDateTimes(true);
    }
});
