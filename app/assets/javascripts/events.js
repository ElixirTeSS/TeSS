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

$(document).on('change', '.event_cost_basis', function () {
    Events.switchCostFields();
    Events.switchAddressFields();
});

$(document).on('ready turbolinks:load', function () {
    Events.switchCostFields();
    Events.switchAddressFields();
});
