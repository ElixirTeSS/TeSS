// initialize the vocab tree
function initialize_vocab_tree(element) {
    element.vocab_widget({
        mode: 'tree',
        endpoint: 'https://vocabs.ardc.edu.au/apps/vocab_widget/proxy/',
        repository: 'anzsrc-for'
    });
}

// add selected processing
function add_selected_tree_item(model_name, field_name, value, name) {
    var newItem = HandlebarsTemplates['dropdowns/item']({
        field_name: field_name,
        model_name: model_name,
        value: value,
        name: name
    });

    $(newItem).appendTo('.' + field_name);
};

// add an event listener
document.addEventListener("turbolinks:load", function () {

    // selected tree item
    $("#vocab-tree").on('treeselect.vocab.ands', function (event) {
        var data = $(event.target).data('vocab')

        if (data.label !== '') {
            var field_name = $("#vocab-tree").attr('data-field');
            var model_name = $("#vocab-tree").attr('data-model');
            add_selected_tree_item(model_name, field_name, data.label, data.label);
        }
    })

});
