const Nodes = {
    addStaff: function () {
        var objectIndex = new Date().getTime(); //Unique index
        var staffFields = $(this).data('template').replace(/replace-me/g, objectIndex);
        var html = $(staffFields).hide();
        var target = $(this).data('target');

        html.appendTo($(target)).slideDown('slow');
        return false;
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
    })
});
