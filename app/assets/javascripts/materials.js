var Materials = {
    externalResources: {
        add: function (title, url) {
            console.log(title + ' ' + url);
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
            newForm = newForm.replace(/replace-me/g, index + 1);
            $('#external-resources-list').append(newForm);

            if (typeof title !== 'undefined' && typeof url !== 'undefined') {
                $('#material_external_resources_attributes_' + (index + 1) + '_url').val(url);
                $('#material_external_resources_attributes_' + (index + 1) + '_title').val(title);
            }
            return false; // Stop form being submitted

        },

        // This is just cosmetic. The actual removal is done by rails,
        //   by virtue of the hidden checkbox being checked when the label is clicked.
        delete: function () {
            $(this).parents('.external-resource-form').fadeOut();
        }
    }
};

$(document).ready(function () {
    $('#external-resources').on('click', '#add-external-resource-btn', Materials.externalResources.add);
    $('#external-resources').on('change', '.delete-external-resource-btn input.destroy-attribute', Materials.externalResources.delete);
});
