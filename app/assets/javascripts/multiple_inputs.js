
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
        var suggestionsUrl = $(this).data('suggestionsUrl');
        var listElement = $(this).find('[data-role="multi-input-list"]');
        var prefix = $(this).data('prefix');
        var addItem = function (value) {
            listElement.find('[data-role="multi-input-add"]').before(HandlebarsTemplates['multi_input/field']({ prefix: prefix, value: value }));
            var input = listElement.find('.multiple-input:last');
            var opts = {
                orientation: 'top',
                triggerSelectOnValidInput: false,
                onSelect: function () {
                    goToBlankInput.apply(input);
                }
            }

            if (suggestionsUrl) {
                opts.serviceUrl = suggestionsUrl;
                opts.dataType = 'json';
                opts.deferRequestBy = 50;
            } else {
                opts.lookupLimit = 10;
                opts.lookup = suggestions;
            }

            input.autocomplete(opts);
            return input;
        };

        // Add a new, or jump to existing blank input
        var goToBlankInput = function () {
            var lastInput = listElement.find('.multiple-list-item:last .multiple-input');
            if (lastInput.val() === '') {
                lastInput.focus();
            } else {
                addItem('').focus();
            }
        }

        var removeItem = function () {
            var item = $(this).parents('.multiple-list-item');
            if (item.siblings('.multiple-list-item').length > 0) {
                item.remove();
            } else {
                item.find('.multiple-input').val('');
            }
            return false;
        }

        var nextItem = function (goToBlank) {
            var nextInput = $(this).parents('.multiple-list-item').next('.multiple-list-item').find('.multiple-input');
            if (nextInput.length) {
                nextInput.focus();
            } else if (goToBlank) {
                goToBlankInput.apply(this);
            }
            $(this).autocomplete('hide');
        }

        var prevItem = function () {
            var lastInput = $(this).parents('.multiple-list-item').prev('.multiple-list-item').find('.multiple-input');
            lastInput.focus();
            var prevItemLength = lastInput.val().length;
            lastInput[0].setSelectionRange(prevItemLength, prevItemLength); // Set cursor to end
            $(this).autocomplete('hide');
        }

        $(this).on('click', '[data-role="multi-input-add"]', function (e) {
            e.preventDefault();
            addItem('').focus();
        });

        $(this).on('keyup', '.multiple-list-item', function (e) {
            var item = $(this);
            var input = item.find('.multiple-input');
            var length = $(input).val().length;
            if ((e.which === 13 || e.which === 188) && length > 0) {
                // Add a new item on enter or comma
                if (e.which === 188) {
                    $(input).val($(input).val().slice(0, -1)); // Remove trailing comma
                }
                nextItem.apply(input, [true]);
            }
        });

        $(this).on('keydown', '.multiple-list-item', function (e) {
            var item = $(this);
            var input = item.find('.multiple-input');
            var length = $(input).val().length;
            if (e.which === 8 && length === 0) {
                e.preventDefault();
                // Remove item on backspace if empty
                prevItem.apply(input);
                removeItem.apply(input);
            } else if (e.which === 46 && input[0].selectionEnd >= length) {
                // Remove next item on delete if cursor is at the end of this field, and next field is empty
                var nextInput = item.next('.multiple-list-item').find('.multiple-input');
                if (nextInput.length && nextInput.val().length === 0) {
                    removeItem.apply(nextInput);
                }
            }
        });

        // Navigate between items with left/right arrow keys
        $(this).on('keydown', '.multiple-input', function (e) {
            var input = $(this);
            var length = $(input).val().length;
            if (e.which === 37 && input[0].selectionEnd === 0) {
                e.preventDefault();
                prevItem.apply(input);
            } else if (e.which === 39 && input[0].selectionEnd >= length) {
                e.preventDefault();
                nextItem.apply(input);
            }
        });

        // Render the existing associations on page load
        if (!listElement.children('.multiple-list-item').length) {
            existing.forEach(addItem);
        }

        $(this).on('click', '.multiple-input-delete', removeItem);
    });
});
