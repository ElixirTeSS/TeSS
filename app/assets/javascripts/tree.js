// initialize the vocab tree
function initialize_vocab_tree() {
    // populate tree unless already populated
    var tree = $('.vocab_tree')
    if (tree == undefined || tree.length == 0) {
        $('#vocab-tree').vocab_widget({
            mode: 'tree',
            endpoint: 'https://vocabs.ardc.edu.au/apps/vocab_widget/proxy/',
            repository: 'anzsrc-for'
        });
    }
};

// add selected processing
function add_selected_tree_item(model_name, field_name, value, name) {
    var parent_name = '.' + field_name
    if (is_duplicate_selection(parent_name, value) == false) {
        var newItem = HandlebarsTemplates['dropdowns/item']({
            field_name: field_name,
            model_name: model_name,
            value: value,
            name: name
        })
        $(newItem).appendTo(parent_name);
    }
};

// check to see if value has already been selected
function is_duplicate_selection(parent_name, value) {
    //console.log('value[' + value + ']')
    var result = false
    var parent = $(parent_name)
    var children = parent.children()
    if (children && children.length > 0) {
        for (let i in children) {
            var child = children[i]
            if (child && child.tagName == 'LI' && child.innerText) {
                //console.log('innerText[' + child.innerText + ']')
                if (child.innerText.trim() == value.trim()) {
                    result = true;
                    break;
                }
            }
        }
    }
    return result
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