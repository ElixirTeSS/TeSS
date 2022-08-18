
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

document.addEventListener("turbolinks:load", function() {
    // Multi-inputs ("app/views/common/multiple_inputs.html.erb")
    $('[data-role="multi-input"]').each(function () {
        var existing = JSON.parse($(this).find('[data-role="multi-input-existing"]').html()) || [];
        var suggestions = JSON.parse($(this).find('[data-role="multi-input-suggestions"]').html()) || [];
        var listElement = $(this).find('[data-role="multi-input-list"]');
        var prefix = $(this).data('prefix');
        var addNewItem = function (value) {
            listElement.append(HandlebarsTemplates['multi_input/field']({ prefix: prefix, value: value }));
            listElement.find('.multiple-input:last').focus();

            return false;
        };

        $(this).on('keydown.autocomplete', '.multiple-list-item input', function() {
            $(this).autocomplete({
                orientation: 'top',
                lookupLimit: 10,
                lookup: suggestions,
                onSelect: function () {
                    addNewItem();
                }
            });
        });

        $(this).on('click', '[data-role="multi-input-add"]', function (e) {
            e.preventDefault();
            addNewItem();
        });

        $(this).on('keypress', '.multiple-input', function (e) {
            /*ADD NEW LINE IF USER HITS ENTER. CONSIDER ADDING MORE LIKE SHIFT, COMMA, ETC*/
            if (e.which == '13' || e.which == '188') {
                e.preventDefault();
                addNewItem();
            } else if (e.which == '8' && $(this).val().length === 0) {
                e.preventDefault();
                $(this).parents('.multiple-list-item').remove();
                listElement.find('.multiple-input:last').focus();
            }
        });

        // Render the existing associations on page load
        if (!listElement.children('.multiple-list-item').length) {
            for (var i = 0; i < existing.length; i++) {
                listElement.append(HandlebarsTemplates['multi_input/field']({ prefix: prefix, value: existing[i]}));
            }
        }
    });

    /* User deletes a free text field such as keyword, author or contributor */
    $(document.body).on('click', '.multiple-input-delete', function (e) {
        $(this).parents('.multiple-list-item').remove();
        return false;
    });
});
