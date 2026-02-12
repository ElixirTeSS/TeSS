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
//= require bootstrap-tab-history
//= require cytoscape
//= require cytoscape-panzoom
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
//= require select2
//= require ahoy
//= require sortable
//= require_tree ./templates
//= require_tree .
//= require_self
//= require turbolinks
//= require ol
//= require ol-geocoder

const Index = {
    applySorting: function () {
        Index.setParam("sort", $("#sort").val());
    },

    applyPerPage: function () {
        Index.setParam("per_page", $("#per_page").val());
    },

    applyDateParam: function (param, value) {
        const url = new URL(window.location.href);
        if (param === 'start' && value === '/') {
            url.searchParams.delete(param);
        } else {
            url.searchParams.set(param, value);
        }
        window.location.replace(url.toString());
    },

    setParam: function (param, value) {
        const url = new URL(window.location.href);
        url.searchParams.set(param, value);
        window.location.replace(url.toString());
    },

    repositionTiles(containerSelector, itemSelector) {
        const container = $(containerSelector);
        container.imagesLoaded(function () {
            container.masonry({
                // options...
                itemSelector: itemSelector,
                columnWidth: 20
            });
        });
    }
}

// Perform an ajax request to load the calendar and replace the contents
window.loadCalendar = function(url) {
    req = $.ajax(url);
    req.done((res) => eval(res));
    return true;
}

// Fix select2 elements being duplicated when the back button is clicked.
// Unfortunately causes the content of the field to be lost if it wasn't saved.
document.addEventListener("turbolinks:before-cache", function() {
    $('.js-select2').select2('destroy');
});

document.addEventListener("turbolinks:load", function(e) {
    // Show the tab associated with the window location hash (e.g. "#packages")
    if (window.location.hash) {
        var tab = $('ul.nav a[href="' + window.location.hash + '"]');
        if (tab.length) {
            // This terrible hack gets around the fact that event handlers in view templates get bound after the
            // `tab.tab('show')` executes, so nothing happens.
            setTimeout(function () { tab.tab("show"); }, 50);
        }
    }

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

    // Load event calendar when tab is shown for the first time
    $('.nav li a[data-calendar]').on("show.bs.tab", function(e) {
        data = e.target.dataset
        // calendar has already been loaded, only perform the filter sidebar url fragment replacing
        if (!data.loaded) {
            let url = data.calendar;
            if (date = localStorage.getItem('calendar_start_date')) {
                // Only use the start date in localstorage if it is in the future
                if (Date.parse(date) > Date.now() - 60*60*24*30*1000) url += '&start_date=' + date
            }

            loadCalendar(url);
            // avoid loading again on the second click
            data.loaded = true;
        }
    });

    // after switching tabs automatically update the url fragment
    $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
        addTabToFilters(e.target.href.split('#').pop());
        // and reposition masonry tiles
        Index.repositionTiles('.masonry', '.masonry-brick');
    });

    // Manually trigger bootstrap tab history (we should probably remove the dependency and reimplement in a turbolink-compatible way)
    // Specialised form of https://github.com/mnarayan01/bootstrap-tab-history/blob/master/vendor/assets/javascripts/bootstrap-tab-history.js
    // go through the tabs to find one which has ah ref identical to the page we have just moved to and show it
    $('[data-toggle="tab"]').each(function() {
        if (("#" + this.href.split("#").pop()) === window.location.hash) {
            if (!("active" in this.parentElement.classList)) {
                $(this).tab('show'); 
            }
        }
    })

    // Masonry
    $(".nav-tabs a").on("shown.bs.tab", function(e) {
        Index.repositionTiles('.masonry', '.masonry-brick');
    });

    $(window).on("orientationchange", function() {
        Index.repositionTiles('.masonry', '.masonry-brick');
    });

    Index.repositionTiles('.masonry', '.masonry-brick');

    new Clipboard(".clipboard-btn");

    // Autocompleters ("app/views/common/_autocompleter.html.erb")
    Autocompleters.init();

    // Collaborations ("app/views/collaborations/_collaborators_button.html.erb")
    Collaborations.init();

    // Address finder ("app/views/events/partials/_address_finder.html.erb")
    MapSearch.init();

    // Map on event show page
    EventMap.init();

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

    Tracking.init();

    Collections.init();

    LearningPaths.init();

    $('.tess-expandable').each(function () {
        if (this.dataset.origHeight) {
            return;
        }
        var limit = this.dataset.heightLimit || 300;

        if (this.clientHeight > limit) {
            if (this.dataset.origHeight) { // Prevent double bind
                return true;
            }
            this.dataset.origHeight = this.clientHeight;
            this.style.maxHeight = '' + limit + 'px';
            this.classList.add('tess-expandable-closed');
            const btn = $('<a href="#" class="tess-expandable-btn">Show more</a>');
            btn.insertAfter($(this));
        }
    });

    $('.faq .question dt').click(function () {
        var button = $(this).find('.expand');
        var sign = button.text();
        var question = $(this).parent();

        if (sign === '+') {
            question.addClass('opened');
            button.text('–')
            question.find('dd').show(300);
        } else {
            button.text('+')
            question.removeClass('opened');
            question.find('dd').hide(300);
        }
    });

    $('.js-select2').select2({ theme: 'bootstrap' });

    // Focus select2 search field when the select is opened.
    // Needs timeout because the "select2-container--open" is not yet rendered when the event is fired.
    $(document).on('select2:open', function (e) {
        setTimeout(function () {
            document.querySelector('.select2-container--open .select2-search__field').focus();
        }, 1);
    });

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

$(document).on('click', '[href="#activity_log"]', function () {
    const activityLog = $('#activity_log');

    if (activityLog.length) {
        activityLog.toggle();
        $(this).find('.expand-icon').addClass('collapse-icon').removeClass('expand-icon');
        if (activityLog.is(':visible')) {
            if (!activityLog.find('.activity').length) { // Only load once
                $.ajax({
                    url: activityLog.data('activityPath'),
                    success: function (data) {
                        activityLog.html(data);
                    }
                });
            }
        } else {
            $(this).find('.collapse-icon').addClass('expand-icon').removeClass('collapse-icon');
        }
    }

    return false;
});

$(document).on('click', '.tess-expandable-btn', function (event) {
    event.preventDefault();
    let div = this.previousElementSibling;

    if (!div || !div.classList.contains('tess-expandable')) {
        div = this.parentElement.querySelector('.tess-expandable');
    }

    if (!div) {
        return false;
    }

    const maxHeight = parseInt(div.dataset.origHeight) + 80;
    const limit = parseInt(div.dataset.heightLimit || "300");

    if (div.classList.contains('tess-expandable-closed')) {
        div.classList.add('tess-expandable-open');
        div.classList.remove('tess-expandable-closed');
        div.style.maxHeight = '' + maxHeight + 'px';
        this.innerHTML = 'Show less';
    } else {
        div.classList.remove('tess-expandable-open');
        div.classList.add('tess-expandable-closed');
        div.style.maxHeight = '' + limit + 'px';
        this.innerHTML = 'Show more';
    }

    return false;
});

// sticky-navbar feature
document.addEventListener('turbolinks:load', function () {

  if (!document.querySelector('.sticky-navbar-enabled')) return;

  const header = document.querySelector('.unified-header');
  const navbar = document.querySelector('.navbar');
  const logoImg = document.querySelector('.navbar-brand img');

  window.addEventListener('scroll', function () {
    if (window.scrollY > 0) {
      header?.classList.add('scrolled');
      navbar?.classList.add('scrolled');
      logoImg?.classList.add('scrolled');

    } else {
      header?.classList.remove('scrolled');
      navbar?.classList.remove('scrolled');
      logoImg?.classList.remove('scrolled');
    }
  });
});