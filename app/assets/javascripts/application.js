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
//= require url_checker
//= require_tree ./templates
//= require_tree .
//= require_self
//= require turbolinks

function updateURLParameter(url, param, paramVal){
    var newAdditionalURL = "";
    var tempArray = url.split("?");
    var baseURL = tempArray[0];
    var additionalURL = tempArray[1];
    var temp = "";
    if (additionalURL) {
        tempArray = additionalURL.split("&");
        for (i=0; i<tempArray.length; i++){
            if(tempArray[i].split('=')[0] != param){
                newAdditionalURL += temp + tempArray[i];
                temp = "&";
            }
        }
    }
    var rows_txt = temp + "" + param + "=" + paramVal;
    return baseURL + "?" + newAdditionalURL + rows_txt;
}

function redirect_to_sort_url(){
    window.location.replace(
        updateURLParameter(
            window.location.href,
            'sort',
            $('#sort').find(":selected").val()
        )
    )
}

function reposition_tiles(container, tile_class){
    var $container = $('.' + container);
    
    $container.imagesLoaded(function () {
        $container.masonry({
            // options...
            itemSelector: '.' + tile_class,
            columnWidth: 20
        });
    });
}

$(document).ready(function () {
    // Show the tab associated with the window location hash (e.g. "#packages")
    if (window.location.hash) {
        var tab = $('ul.nav a[href="' + window.location.hash + '"]');
        if (tab.length) {
            tab.tab('show');
        }
    }

    // Store the open tab in the window location hash
    $('.nav-tabs a').on("shown.bs.tab", function(e) {
        window.location.hash = this.hash;
    });

    // Disabled tabs
    $('.nav-tabs li a[data-toggle="tooltip"]').tooltip();
    $('.nav-tabs li.disabled a').click(function (e) { e.preventDefault(); return false });

    // Datetime pickers
    $(function () {
        $('[data-datetimepicker]').datetimepicker({
            format: 'YYYY-MM-DD HH:mm',
            sideBySide: true
        });
    });

    $(document).on('click', '.delete-list-item', function () {
        $(this).parents('li').remove();
        return false;
    });

    // Masonry
    $('.nav-tabs a').on("shown.bs.tab", function(e) {
        reposition_tiles('masonry', 'masonry-brick');
    });
    $(window).on('orientationchange', function() {
        reposition_tiles('masonry', 'masonry-brick');
    });
    reposition_tiles('masonry', 'masonry-brick');


    new Clipboard('.clipboard-btn');

    // Autocompleters ("app/views/common/_autocompleter.html.erb")
    $('[data-role="autocompleter-group"]').each(function () {
        var existingValues = JSON.parse($(this).find('[data-role="autocompleter-existing"]').html()) || [];
        var listElement = $(this).find('[data-role="autocompleter-list"]');
        var inputElement = $(this).find('[data-role="autocompleter-input"]');
        var url = $(this).data('url');
        var prefix = $(this).data('prefix');
        var labelField = $(this).data('labelField') || 'title';
        var idField = $(this).data('idField') || 'id';
        var templateName = $(this).data('template') || 'autocompleter/resource';

        // Render the existing associations on page load
        for (var i = 0; i < existingValues.length; i++) {
            listElement.append(HandlebarsTemplates[templateName](existingValues[i]));
        }

        inputElement.autocomplete({
            serviceUrl: url,
            dataType: 'json',
            deferRequestBy: 300, // Wait 300ms before submitting to stop search being flooded
            paramName: 'q',
            transformResult: function(response) {
                return {
                    suggestions: $.map(response, function(item) {
                        return { value: item[labelField], data: item[idField], item: item };
                    })
                };
            },
            onSelect: function (suggestion) {
                // Don't add duplicates
                if (!$("[data-id='" + suggestion.data + "']", listElement).length) {
                    var obj = { item: suggestion.item };
                    if (prefix) {
                        obj.prefix = prefix;
                    }

                    listElement.append(HandlebarsTemplates[templateName](obj));
                }

                $(this).val('').focus();
            },
            onSearchStart: function (query) {
                query.q = query.q + '*';
                inputElement.addClass('loading');
            },
            onSearchComplete: function () {
                inputElement.removeClass('loading');
            }
        });
    });

    var setStarButtonState = function (button) {
        if (button.data('starred')) {
            button.html("<i class='fa fa-star'> </i> Un-star");
        } else {
            button.html("<i class='fa fa-star-o'> </i> Star");
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
                url: '/stars',
                data: { star: { resource_id: resource.id, resource_type: resource.type } },
                success: function () {
                    button.data('starred', !starred);
                    setStarButtonState(button);
                },
                complete: function () {
                    button.removeClass('loading');
                }
            });
        })
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
});
