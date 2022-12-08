// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery.turbolinks
//= require jquery_ujs
//= require bootstrap-sprockets
//= require cytoscape
//= require cytoscape-panzoom
//= require jscolor
//= require jquery.simplecolorpicker.js
//= require split
//= require handlebars.runtime
//= require handlebars_helpers
//= require masonry.pkgd
//= require imagesloaded.pkgd
//= require markdown-it
//= require URI
//= require moment
//= require eonasdan-bootstrap-datetimepicker
//= require devbridge-autocomplete
//= require clipboard
//= require ardc_vocab_widget_v2
//= require_tree ./templates
//= require_tree .
//= require_self
//= require turbolinks

function toggleDefinition(el) {
    var sign = $(el).html();

    if (sign === '+') {
        $(el).parent().parent().parent().addClass('opened');
        $(el).text('–')
        $(el).parent().parent().next().show(300);
    } else {
        $(el).text('+')
        $(el).parent().parent().parent().removeClass('opened');
        $(el).parent().parent().next().hide(300);
    }
}

function updateURLParameter(url, param, paramVal){
    var newAdditionalURL = "";
    var tempArray = url.split("?");
    var baseURL = tempArray[0];
    var additionalURL = tempArray[1];
    var temp = "";

    if (additionalURL) {
        tempArray = additionalURL.split("&");
        for (var i=0; i<tempArray.length; i++){
            if(tempArray[i].split("=")[0] != param){
                newAdditionalURL += temp + tempArray[i];
                temp = "&";
            }
        }
    }
    var rowsTxt = temp + "" + param + "=" + paramVal;
    return baseURL + "?" + newAdditionalURL + rowsTxt;
}

function redirect_to_sort_url(){
    window.location.replace(
        updateURLParameter(
            window.location.href,
            "sort",
            $("#sort").find(":selected").val()
        )
    );
}

function reposition_tiles(container, tileClass){
    var $container = $("." + container);

    $container.imagesLoaded(function () {
        $container.masonry({
            // options...
            itemSelector: "." + tileClass,
            columnWidth: 20
        });
    });
}

document.addEventListener("turbolinks:load", function() {
    // Disabled tabs
    $(".nav-tabs li a[data-toggle='tooltip']").tooltip();
    $(".nav-tabs li.disabled a").click(function (e) { e.preventDefault(); return false });

    // Datetime pickers
    $("[data-datetimepicker]").datetimepicker({
        format: "YYYY-MM-DD HH:mm",
        sideBySide: true
    });

    // Date pickers
    $("[data-datepicker]").datetimepicker({
        format: "YYYY-MM-DD"
    });


    // On events form, if start date > end date, update the end date.
    $("#event_form").on("dp.change", function (e) {
        // Really awkward way of doing it
        if ($(e.target).find("#event_start").length) {
            var startPicker = $("#event_start").parents("[data-datetimepicker]").data("DateTimePicker");
            var endPicker = $("#event_end").parents("[data-datetimepicker]").data("DateTimePicker");
            var endDate = endPicker.date();
            var startDate = startPicker.date();
            if (startDate > endDate) {
                endDate = endDate.set({
                    "year": startDate.year(),
                    "month": startDate.month(),
                    "date": startDate.date()
                });
                endPicker.date(endDate);
            }
        }
    });

    // Masonry
    $(".nav-tabs a").on("shown.bs.tab", function(e) {
        reposition_tiles('masonry', 'masonry-brick');
    });
    $(window).on("orientationchange", function() {
        reposition_tiles("masonry", "masonry-brick");
    });
    reposition_tiles("masonry", "masonry-brick");

    new Clipboard(".clipboard-btn");

    // Autocompleters ("app/views/common/_autocompleter.html.erb")
    Autocompleters.init();

    // Collaborations ("app/views/collaborations/_collaborators_button.html.erb")
    Collaborations.init();

    // Address finder ("app/views/events/partials/_address_finder.html.erb")
    MapSearch.init();

    // Map on event show page
    Map.init();

    // Map on event index page
    EventsMap.init();

    // Testing section on source page
    Sources.init();

    var setStarButtonState = function (button) {
        if (button.data('starred')) {
            button.html("<i class='icon icon-h3 star-fill-icon'> </i>");
        } else {
            button.html("<i class='icon icon-h3 star-icon'> </i>");
        }
    };

    $('[data-role="star-button"]').each(function () {
        var button = $(this);
        var resource = button.data('resource');

        setStarButtonState(button);

        button.click(function () {
            var starred = button.data('starred');
            button.addClass('loading');
            $.ajax({
                method: starred ? 'DELETE' : 'POST',
                dataType: 'json',
                url: button.data('url'),
                data: { star: { resource_id: resource.id, resource_type: resource.type } },
                success: function () {
                    button.data('starred', !starred);
                    setStarButtonState(button);
                },
                complete: function () {
                    button.removeClass('loading');
                }
            });

            return false;
        })
    });

    $('body').scrollspy({
        target: '.about-page-menu',
        offset: 40
    });

    $('.about-page-menu').affix({
        offset: {
            top: 100
        }
    });

    $('.has-popover').each(function () {
        $(this).popover({
            trigger: 'manual'
        }).click(function (e) {
            $(this).popover('toggle');
            e.stopPropagation(); // Stops popover immediately closing from document click handler below.
        }).on('inserted.bs.popover', function () {
            $('.popover').click(function (e) {
                // Prevent clicking the popover content from closing it.
                // Skips the click event on the document, defined below.
                e.stopPropagation();
            })
        })
    });

    $(document).click(function () {
        $('.has-popover').popover('hide');
    });

    $("a[rel~=tooltip], .has-tooltip").tooltip();

    // Prevent form being un-intentionally submitted when enter key is pressed in a text field.
    $(document).on('keydown', 'form.prevent-enter-submit :input:not(textarea):not(:submit)', function(event) {
        if (event.keyCode === 13) {
            return false;
        }
    });

    Nodes.init();

    Fairsharing.init();

    Biotools.init();
});

function truncateWithEllipses(text, max)
{
    return text.substr(0,max-1)+(text.length>max?'&hellip;':'');
}

$(document).on('click', '.delete-list-item', function () {
    $(this).parents('li').remove();
    return false;
});

$(document).on('click', '.clear-autocompleter-singleton', function () {
    var wrapper = $(this).parents('[data-role="autocompleter-group"]');
    $(this).parents('li').remove();
    $('[data-role="autocompleter-input"]', wrapper).show();
    return false;
});

$(document).on('shown.bs.tab', '[href="#activity_log"]', function () {
    var tabPane = $('#activity_log');

    $.ajax({
        url: tabPane.data('activityPath'),
        success: function (data) {
            tabPane.html(data);
        }
    });
});

/**
 * Function that registers a click on an outbound link in Analytics.
 * This function takes a valid URL string as an argument, and uses that URL string
 * as the event label. Setting the transport method to 'beacon' lets the hit be sent
 * using 'navigator.sendBeacon' in browser that support it.
 */
var getOutboundLink = function(url) {
    if (!window.captureClicks) {
        return;
    }
    gtag('event', 'click', {
        'event_category': 'outbound',
        'event_label': url,
        'transport_type': 'beacon',
        'event_callback': function() {} // Not needed
    });
}
