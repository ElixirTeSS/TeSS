const People = {
    add: function (template, list) {
        let newForm = template.clone().html();
        // Ensure the index of the new form is 1 greater than the current highest index, to prevent collisions
        let index = 0;
        $('.person-form', list).each(function () {
            var newIndex = parseInt($(this).data('index'));
            if (newIndex > index) {
                index = newIndex;
            }
        });

        // Replace the placeholder index with the actual index
        newForm = $(newForm.replace(/replace-me/g, index + 1));
        newForm.appendTo(list);
        const nameInput = newForm.find('.person-name');
        const orcidInput = newForm.find('.person-orcid');
        const opts = {
            orientation: 'top',
            triggerSelectOnValidInput: false,
            onSelect: function (suggestion) {
                orcidInput.val(suggestion.data.orcid);
            },
            transformResult: function(response) {
                return {
                    suggestions: $.map(response.suggestions, function(item) {
                        item.data.hint = item.data.orcid;
                        return item;
                    })
                };
            },
            formatResult: Autocompleters.formatResultWithHint
        }

        opts.serviceUrl = list.parents('[data-role="people-form"]').data('autocompleteUrl');
        opts.dataType = 'json';
        opts.deferRequestBy = 100;

        nameInput.autocomplete(opts);

        return newForm;
    },

    delete: function () {
        $(this).parents('.person-form').fadeOut('fast', function() {
            $(this).remove();
        });
    },

    init: function () {
        $('[data-role="people-form"]').each(function () {
            const form = $(this);
            const template = form.find('[data-role="people-form-template"]');
            const list = form.find('[data-role="people-form-list"]');

            form.find('[data-role="people-form-add"]').click(function (e) {
                e.preventDefault();
                const nextItem = People.add(template, list);
                nextItem.find('input.form-control:first').focus();
            });

            // Add new person if enter is pressed on final person, otherwise focus the next person in the list.
            $(form).on('keyup', 'input', function (e) {
                if (e.which === 13) {
                    e.preventDefault();
                    let nextItem = $(e.target).parents('.person-form').next('.person-form');
                    if (!nextItem.length) {
                        nextItem = People.add(template, list);
                    }
                    nextItem.find('input.form-control:first').focus();
                }
            });
        });

        $('.delete-person-btn input.destroy-attribute').change(People.delete);
    }
};
