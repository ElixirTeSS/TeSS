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
    var newItem = HandlebarsTemplates['dropdowns/item']({ field_name: field_name,
        model_name: model_name, 
        value: value, 
        name: name });
    
    $(newItem).appendTo('.' + field_name);
}

/* Adds a new option to the list of dropdown options. Used when a package is deselected (e.g. delete button pressed)"*/
function add_dropdown_option(field_name, name, value){
    var newOption = HandlebarsTemplates['dropdowns/option']({ field_name: field_name,
        value: value,
        name: name });

    $(newOption).appendTo('.' + field_name + '-options')
}


document.addEventListener("turbolinks:load", function() {
    /*
     * User selects a new package to add the resource to.
     * This adds a new added item and removes it from the dropdown
     * */
    $(document.body).on('click', '.dropdown-option', function (e) {
        var selected_val = $(this).data('value');
        if (selected_val !== '') {
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
        add_dropdown_option($(this).attr('data-field'), $(this).attr('data-name'), $(this).attr('data-value'));
        list_item.remove(); // This should also remove the hidden input field as we have removed the parent div that contains the disabled text field, hidden field and close/delete button
    });
});
