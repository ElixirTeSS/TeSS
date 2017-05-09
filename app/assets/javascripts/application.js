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

    // Binding on change event to dynamically added input text fields means
    // we have to bind the event to a parent element because the input doesn't exist yet.
    $(document).on('blur', '.scientific_topic_names', function () {
        if ($(this).val() != '') {
            $(this).attr('readonly', 'true');
        }
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
});
