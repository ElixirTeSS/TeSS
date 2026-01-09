var SourceFilters = {
    last_id: function () {
        var existing_list_item_ids = $(".source-filter-form").map(function (i, c) { return $(c).data("id-in-filter-list") });
        if (existing_list_item_ids.length == 0) return 0;
        return Math.max.apply(null, existing_list_item_ids) + 1;
    },

    add: function () {
        var new_form = $($('#source-filter-template').clone().html().replace(/REPLACE_ME/g, SourceFilters.last_id()));
        new_form.appendTo('#source-filter-list');

        return false; // Stop form being submitted
    },

    add_block_filter: function () {
        var new_form = $($('#source-filter-template').clone().html().replace(/REPLACE_ME/g, SourceFilters.last_id()).replace(/allow/, 'block'));
        new_form.appendTo('#source-block-list');

        return false; // Stop form being submitted
    },

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
