var Collections = {
    init: function () {
        $("[data-role='collection-items-group']").each(function () {
            // Set up drag/drop
            var list = $('.collection-items', $(this))[0];
            const collectionItems = new Sortable.default(list, {
                draggable: 'li.collection-item',
                handle: '.collection-item-handle'
            });

            collectionItems.on('drag:stopped', function (e) {
                // Re-compute orders after dropping.
                Collections.recalculateOrder(e.data.sourceContainer);
            });

            // Set up autocompleter
            var origTransform = Autocompleters.transformFunctions[$(this).data("transformFunction") || "default"];
            Autocompleters.initGroup(this, {
                resourceType: $(this).data("resourceType"),
                transformFunction: function (response, config) {
                    var result = origTransform(response, config);
                    result.suggestions.forEach(function (sugg) {
                        sugg.data.item.resource_type = config.resourceType;
                        sugg.data.item.resource_id = sugg.data.item.id;
                        sugg.data.item.id = null;
                        sugg.data.id = sugg.data.item.resource_type + '-' + sugg.data.item.resource_id
                    });
                    return result;
                }
            });


            $(this).on('autocompleters:added', function () {
                // Re-compute orders after new item added.
                Collections.recalculateOrder(this);
            });

            $(this).on('click', '[data-role="delete-collection-item"]', function (e) {
                // If the collection item yet saved, just delete from the DOM,
                //  otherwise, apply visible styling to show it will be deleted, which can be
                //  undone if the button is clicked again
                var item = $(this).closest('.collection-item');
                var checkbox = $('input', $(this));
                if (!checkbox.length) { // No checkbox is rendered if item is not persisted yet.
                    var list = $(this).closest('ul')[0];
                    // Re-compute orders after item removed.
                    item.remove();
                    Collections.recalculateOrder(list);
                } else {
                    if (checkbox.is(':checked')) {
                        checkbox.prop('checked', false);
                        $('input[type=text]', item).prop('disabled', false);
                        item.removeClass('pending-delete');
                    } else {
                        checkbox.prop('checked', true);
                        $('input[type=text]', item).prop('disabled', true);
                        item.addClass('pending-delete');
                    }
                }

                return false;
            });

            // Calculate initial order - order from database may have gaps if items were deleted.
            Collections.recalculateOrder(list);
        });
    },

    recalculateOrder: function (container) {
        var order = 1;
        container.querySelectorAll('li.collection-item').forEach(function (li) {
            li.querySelector('[data-role="item-order"]').value = order;
            li.querySelector('.item-order-label').innerText = order;
            order++;
        });
    }
}
