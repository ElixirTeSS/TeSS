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
        /* remove HTML autocfocus attribute from element */
        this.blur()
        var field_name = $(this).attr('data-field');
        new_multiple_input_field(field_name);
    })
    $(document.body).on('keypress', '.multiple-input', function(e){
        /*ADD NEW LINE IF USER HITS ENTER. CONSIDER ADDING MORE LIKE SHIFT, COMMA, ETC*/
        if (e.which == '13' || e.which == '188') {
            event.preventDefault(); /* stops enter submitting form */
            var field_name = $(this).attr('data-field');
            new_multiple_input_field(field_name);
        }
    })
    /* User deletes a free text field such as keyword, author or contributor */
    $(document.body).on('click', '.multiple-input-delete', function(e){
        var list_item = $(this).parent();
        remove_list_item(list_item)
    })
    /*
     * User selects a new package to add the material to.
     * This adds a new added item and removes it from the dropdown
     * */
    $(document.body).on('click', '.dropdown-option', function(e){
        var selected_val = $(this).val();
        if (selected_val != ''){
            var field_name = $(this).parent().attr('data-field');
            var selected_text = $(this).text();
            add_selected_dropdown_item(field_name, selected_val, selected_text);
            $('#' + field_name + '-id-' + selected_val).remove();
        }
    })
    /*
     * User removes a package from a material.
     * This adds the package back into the dropdown options.
     */
    $(document.body).on('click', '.dropdown-option-delete', function(e){
        var list_item = $(this).parent();
        add_dropdown_option($(this).attr('data-field'),
            $(this).attr('data-name'),
            $(this).attr('data-value'));
        list_item.remove()
    })

    /*FUNCTIONS*/
    /*
     * Adds a new selected item to the field_name div with the values and names passed
     */
    function add_selected_dropdown_item(field_name, value, name){
        var label = '<input type="text" class="multiple-input form-control" data-field="package" name="material[package_ids][]" ' +
            'value="' + value + '" style="display:none;"> ' + name + '</text>';
        var delete_button = '<input type="button" value="&times;" class="dropdown-option-delete" data-field="package"' +
            'data-value="' + value + '" data-name="' + name + '"/>';

        var list_item_div = $('<div class="multiple-list-item">').appendTo('.' + field_name);
        $(label).appendTo(list_item_div);
        $(delete_button).appendTo(list_item_div);
    }
    /*
     * Creates a new input box for free text fields as a child of the field_name div
     */
    function new_multiple_input_field(field_name){
        var input_box = '<input type="text" class="multiple-input form-control" data-field="'
            + field_name + '" name="material[' + field_name + 's][]" />';
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
})