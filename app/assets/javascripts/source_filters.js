var SourceFilters = {
    add: function () {
        var newForm = $($('#source-filter-template').clone().html());
        newForm.appendTo('#source-filter-list');

        return false; // Stop form being submitted
    },

    // This is just cosmetic. The actual removal is done by rails,
    //   by virtue of the hidden checkbox being checked when the label is clicked.
    delete: function () {
        $(this).parents('.source-filter-form').fadeOut();
    }
};

document.addEventListener("turbolinks:load", function() {
    $('#source-filters')
        .on('click', '#add-source-filter-btn', SourceFilters.add)
        .on('click', '#add-source-filter-btn-label', SourceFilters.add)
        .on('change', '.delete-source-filter-btn input.destroy-attribute', SourceFilters.delete);
});
