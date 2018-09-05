var ExternalResources = {
    add: function (title, url) {
        var newForm = $('#external-resource-template').clone().html();

        // Ensure the index of the new form is 1 greater than the current highest index, to prevent collisions
        var index = 0;
        $('#external-resources-list .external-resource-form').each(function () {
            var newIndex = parseInt($(this).data('index'));
            if (newIndex > index) {
                index = newIndex;
            }
        });

        // Replace the placeholder index with the actual index
        newForm = $(newForm.replace(/replace-me/g, index + 1));
        newForm.appendTo('#external-resources-list');

        if (typeof title !== 'undefined' && typeof url !== 'undefined') {
            $('.external-resource-title', newForm).val(title);
            $('.external-resource-url', newForm).val(url);
        }

        return false; // Stop form being submitted
    },

    // This is just cosmetic. The actual removal is done by rails,
    //   by virtue of the hidden checkbox being checked when the label is clicked.
    delete: function () {
        $(this).parents('.external-resource-form').fadeOut();
    }
};

document.addEventListener("turbolinks:load", function() {
    $('#external-resources')
        .on('click', '#add-external-resource-btn', ExternalResources.add)
        .on('change', '.delete-external-resource-btn input.destroy-attribute', ExternalResources.delete);
});
