
/**
 * Created by Niall Beard on 07/01/2016.
 *
 * Multiple Input
 *  - For free text fields such as keyword, author, or contributor
 *  - Functions: Add, Delete
 */

/*
 * Creates a new input box for free text fields as a child of the field_name div
 */
function add_multiple_input_field(model_name, field_name, field_name_plural, placeholder_text){
    var input_box = '<input type="text" class="multiple-input form-control ' + field_name + 's" ' +
        'autocomplete="off"' +
        'data-field="' + field_name + '" ' +
        'data-model="' + model_name + '" ' +
        'placeholder="' + placeholder_text + '" ' +
        'name="' + model_name + '[' + field_name_plural + '][]"' +
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

function handleMultipleInputAdd(element) {
    var field_name = $(element).attr('data-field');
    var field_name_plural = $(element).attr('data-field-plural');
    var model_name = $(element).attr('data-model');
    var placeholder_text = $(element).attr('placeholder-text');

    add_multiple_input_field(model_name, field_name, field_name_plural, placeholder_text);
}

$(document).ready(function(){
    /*EVENTS*/
    /*
     * User clicks ADD NEW for a free text field such as keyword, author, or contributor
     * OR they hit enter whilst in a free text field box
     */
    $(document.body).on('click', '.multiple-input-add', function(e){
        /* remove HTML autofocus attribute from element */
        this.blur();
        handleMultipleInputAdd(this);
    });
    $(document.body).on('keypress', '.multiple-input', function(e){
        /*ADD NEW LINE IF USER HITS ENTER. CONSIDER ADDING MORE LIKE SHIFT, COMMA, ETC*/
        if (e.which == '13' || e.which == '188') {
            event.preventDefault(); /* stops enter submitting form */
            handleMultipleInputAdd(this);
        }
    });
    /* User deletes a free text field such as keyword, author or contributor */
    $(document.body).on('click', '.multiple-input-delete', function(e){
        var list_item = $(this).parent();
        remove_list_item(list_item)
    });
});
