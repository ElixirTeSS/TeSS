var SourceFilters = {
    add: function () {
        var existing_list_item_ids = $("#source-filter-list").children("div").map(function (i, c) { return $(c).data("id-in-filter-list") });
        var new_id = Math.max(Math.max.apply(null, existing_list_item_ids) + 1, 0);
        var new_form = $($('#source-filter-template').clone().html().replace(/REPLACE_ME/g, new_id));
        new_form.appendTo('#source-filter-list');

        return false; // Stop form being submitted
    },

    add_block_filter: function () {
        var existing_list_item_ids = $("#source-block-list").children("div").map(function (i, c) { return $(c).data("id-in-filter-list") });
        var new_id = Math.max(Math.max.apply(null, existing_list_item_ids) + 100000, 0);
        var new_form = $($('#source-filter-template').clone().html().replace(/REPLACE_ME/g, new_id).replace(/allow/, 'block'));
        new_form.appendTo('#source-block-list');

        return false; // Stop form being submitted
    },

    // This is just cosmetic. The actual removal is done by rails,
    //   by virtue of the hidden checkbox being checked when the label is clicked.
    delete: function () {
        $(this).parents('.source-filter-form').fadeOut().find("input[name$='[_destroy]']").val("true");
    }
};

document.addEventListener("turbolinks:load", function () {
    $('#source-filters')
        .on('click', '#add-source-filter-btn', SourceFilters.add)
        .on('click', '#add-source-filter-btn-label', SourceFilters.add)
        .on('click', '.delete-source-filter-btn', SourceFilters.delete);
    $('#source-block-filters')
        .on('click', '#add-source-block-filter-btn', SourceFilters.add_block_filter)
        .on('click', '#add-source-block-filter-btn-label', SourceFilters.add_block_filter)
        .on('click', '.delete-source-filter-btn', SourceFilters.delete);
});
