var Authors = {
    add: function (firstName, lastName, orcid) {
        var newForm = $('#author-template').clone().html();

        // Ensure the index of the new form is 1 greater than the current highest index, to prevent collisions
        var index = 0;
        $('#authors-list .author-form').each(function () {
            var newIndex = parseInt($(this).data('index'));
            if (newIndex > index) {
                index = newIndex;
            }
        });

        // Replace the placeholder index with the actual index
        newForm = $(newForm.replace(/replace-me/g, index + 1));
        newForm.appendTo('#authors-list');

        if (typeof firstName !== 'undefined' && typeof lastName !== 'undefined') {
            $('.author-first-name', newForm).val(firstName);
            $('.author-last-name', newForm).val(lastName);
            if (typeof orcid !== 'undefined') {
                $('.author-orcid', newForm).val(orcid);
            }
        }

        return false; // Stop form being submitted
    },

    // This is just cosmetic. The actual removal is done by rails,
    //   by virtue of the hidden checkbox being checked when the label is clicked.
    delete: function () {
        $(this).parents('.author-form').fadeOut();
    }
};

document.addEventListener("turbolinks:load", function() {

    $('#authors')
        .on('click', '#add-author-btn', Authors.add)
        .on('change', '.delete-author-btn input.destroy-attribute', Authors.delete);
});
