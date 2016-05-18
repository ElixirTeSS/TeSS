const Nodes = {
    addStaff: function () {
        var objectIndex = new Date().getTime(); //Unique index
        var staffFields = $(this).data('template').replace(/replace-me/g, objectIndex);
        var html = $(staffFields).hide();
        var target = $(this).data('target');
        html.data('newRecord', true);

        html.appendTo($(target)).slideDown('slow')
        return false;
    },
    removeStaff: function () {
        // If the staff member is not yet saved, just delete from the DOM,
        //  otherwise, apply visible styling to show it will be deleted, which can be
        //  undone if the button is clicked again
        var parent = $(this).parents('.staff-member-fields');
        if(parent.data('newRecord')) {
            parent.remove();
        } else {
            if($(this).is(':checked')) {
                $('input[type=text]', parent).prop('disabled', true);
                parent.addClass('pending-delete');
            } else {
                $('input[type=text]', parent).prop('disabled', false);
                parent.removeClass('pending-delete');
            }
        }
    }
};

$(function () {
    $('[data-role="add-node-staff-button"]').each(function () {
        var template = $(this).next('[data-role="add-node-staff-template"]');
        // Store the template's HTML on this DOM object
        $(this).data('template', template.html());
        // Delete the template from the DOM, don't need anymore.
        template.remove();
        // Bind click event
        $(this).click(Nodes.addStaff);
    });

    $('#staff-list').on('change', '[data-role="delete-node-staff-button"]', Nodes.removeStaff);
});
