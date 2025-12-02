var People = {
    add: function (role) {
        var templateId = '#person-' + role + '-template';
        var listId = '#person-' + role + '-list';
        var newForm = $(templateId).clone().html();

        // Ensure the index of the new form is 1 greater than the current highest index, to prevent collisions
        var index = 0;
        $(listId + ' .person-form').each(function () {
            var newIndex = parseInt($(this).data('index'));
            if (newIndex > index) {
                index = newIndex;
            }
        });

        // Replace the placeholder index with the actual index
        newForm = $(newForm.replace(/replace-me/g, index + 1));
        newForm.appendTo(listId);

        return false; // Stop form being submitted
    },

    // This is just cosmetic. The actual removal is done by rails,
    //   by virtue of the hidden checkbox being checked when the label is clicked.
    delete: function () {
        $(this).parents('.person-form').fadeOut();
    }
};

document.addEventListener("turbolinks:load", function() {

    $('[id^="person-"]')
        .on('click', '[id^="add-person-"]', function() {
            var role = $(this).data('role');
            People.add(role);
            return false;
        })
        .on('change', '.delete-person-btn input.destroy-attribute', People.delete);
});
