/**
 * Created by Niall Beard on 07/01/2016.
 *
 * Dropdown Option
 *  - For selecting dropdown options such as package, licence, audience
 *  - Functions: Select, Delete
 */

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

/* Adds a new option to the list of dropdown options. Used when a package is deselected (e.g. delete button pressed)"*/
function add_dropdown_option(field_name, name, value){
    $('<li class="dropdown-option" id="' + field_name + '-id-' + value + '" ' +
        'value="' + value + '"><a>' + name + '</a></li>').appendTo('.' + field_name + '-options')
}


$(document).ready(function() {
    /*
     * User selects a new package to add the resource to.
     * This adds a new added item and removes it from the dropdown
     * */
    $(document.body).on('click', '.dropdown-option', function (e) {
        var selected_val = $(this).val();
        if (selected_val != '') {
            var field_name = $(this).parent().attr('data-field');
            var model_name = $(this).parent().attr('data-model');
            var selected_text = $(this).text();
            add_selected_dropdown_item(model_name, field_name, selected_val, selected_text);
            $('#' + field_name + '-id-' + selected_val).remove();
        }
    });
    /*
     * User removes a package from a resource.
     * This adds the package back into the dropdown options.
     */
    $(document.body).on('click', '.dropdown-option-delete', function (e) {
        var list_item = $(this).parent();
        add_dropdown_option($(this).attr('data-field'),
            $(this).attr('data-name'),
            $(this).attr('data-value'));
        list_item.remove(); // This should also remove the hidden input field as we have removed the parent div that contains the disabled text field, hidden field and close/delete button
    });
});
