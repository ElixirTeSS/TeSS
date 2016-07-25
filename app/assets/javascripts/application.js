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
//= require_tree ./templates
//= require_tree .
//= require_self
//= require turbolinks

function redirect_to_sort_url(){
    window.location.replace(
        updateURLParameter(
            window.location.href,
            'sort',
            $('#sort').find(":selected").val()
        )
    )
}

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

/**
 * Created by Niall Beard on 07/01/2016.
 *
 * Multiple Input
 *  - For free text fields such as keyword, author, or contributor
 *  - Functions: Add, Delete
 *
 * Dropdown Option
 *  - For selecting dropdown options such as package, licence, audience
 *  - Functions: Select, Delete
 */


$(document).ready(function(){
    /*EVENTS*/
    /*
     * User clicks ADD NEW for a free text field such as keyword, author, or contributor
     * OR they hit enter whilst in a free text field box
     */
    $(document.body).on('click', '.multiple-input-add', function(e){
        /* remove HTML autofocus attribute from element */
        console.log('Clicked on "Add new ... "')

        this.blur()
        var field_name = $(this).attr('data-field');
        var model_name = $(this).attr('data-model');
        var placeholder_text = $(this).attr('placeholder-text');

        add_multiple_input_field(model_name, field_name, placeholder_text);
    })
    $(document.body).on('keypress', '.multiple-input', function(e){
        /*ADD NEW LINE IF USER HITS ENTER. CONSIDER ADDING MORE LIKE SHIFT, COMMA, ETC*/
        if (e.which == '13' || e.which == '188') {
            event.preventDefault(); /* stops enter submitting form */
            var field_name = $(this).attr('data-field');
            var model_name = $(this).attr('data-model');
            var placeholder_text = $(this).attr('placeholder-text');

            add_multiple_input_field(model_name, field_name, placeholder_text);
        }
    })
    /* User deletes a free text field such as keyword, author or contributor */
    $(document.body).on('click', '.multiple-input-delete', function(e){
        var list_item = $(this).parent();
        remove_list_item(list_item)
    })
    /*
     * User selects a new package to add the resource to.
     * This adds a new added item and removes it from the dropdown
     * */
    $(document.body).on('click', '.dropdown-option', function(e){
        var selected_val = $(this).val();
        if (selected_val != ''){
            var field_name = $(this).parent().attr('data-field');
            var model_name = $(this).parent().attr('data-model');
            console.log(field_name);
            console.log(model_name);
            var selected_text = $(this).text();
            add_selected_dropdown_item(model_name, field_name, selected_val, selected_text);
            $('#' + field_name + '-id-' + selected_val).remove();
        }
    })
    /*
     * User removes a package from a resource.
     * This adds the package back into the dropdown options.
     */
    $(document.body).on('click', '.dropdown-option-delete', function(e){
        var list_item = $(this).parent();
        add_dropdown_option($(this).attr('data-field'),
            $(this).attr('data-name'),
            $(this).attr('data-value'));
        list_item.remove(); // This should also remove the hidden input field as we have removed the parent div that contains the disabled text field, hidden field and close/delete button
    })
})

/*FUNCTIONS*/
/*
 * Adds a new selected item to the field_name div with the values and names passed
 */
function add_selected_dropdown_item(model_name, field_name, value, name){
    var item_name = '<input type="text" class="multiple-input form-control" ' +
                    'data-field="' + field_name + '" data-model="' + model_name + '" ' + 
                    'name="' + model_name + '[' + field_name + '_ids][]" ' +
                    'value="' + name + '" readonly="readonly" disabled="disabled" />';
                    
    var item_value = '<input type="hidden" data-field="' + field_name + '" name="' + model_name + '[' + field_name + '_ids][]" ' +
        'value="' + value + '" />';
    var delete_button = '<input type="button" value="&times;" class="dropdown-option-delete" data-field="' + field_name + '"' +
        'data-value="' + value + '" data-name="' + name + '"/>';

    var list_item_div = $('<div class="multiple-list-item">').appendTo('.' + field_name);
    $(item_name).appendTo(list_item_div);
    $(item_value).appendTo(list_item_div);
    $(delete_button).appendTo(list_item_div);
}

/*
 * Creates a new input box for free text fields as a child of the field_name div
 */
function add_multiple_input_field(model_name, field_name, placeholder_text){
    var input_box = '<input type="text" class="multiple-input form-control ' + field_name + 's" ' +
                    'autocomplete="off"' +
                    'data-field="' + field_name + '" ' +
                    'data-model="' + model_name + '" ' +
                    'placeholder="' + placeholder_text + '" ' +
                    'name="' + model_name + '[' + field_name + 's][]"' +
                    ' />';
    var delete_button = '<input type="button" value="&times;" class="multiple-input-delete" data-field="keyword" tabindex=300/>';

    var list_item_div = $('<div class="multiple-list-item">').appendTo('.' + field_name);
    $(input_box).appendTo(list_item_div).focus();
    $(delete_button).appendTo(list_item_div);
}
/* removes an item */
function remove_list_item(list_item){
    list_item.remove();
}
/* Adds a new option to the list of dropdown options. Used when a package is deselected (e.g. delete button pressed)"*/
function add_dropdown_option(field_name, name, value){
    $('<li class="dropdown-option" id="' + field_name + '-id-' + value + '" ' +
        'value="' + value + '"><a>' + name + '</a></li>').appendTo('.' + field_name + '-options')
}

$(document).ready(function () { reposition_tiles('masonry', 'masonry-brick'); });
