// initialize the vocab tree
function initializeVocabTree() {
    // populate tree unless already populated
    var tree = $(".vocab_tree");
    if (typeof tree === "undefined" || tree.length === 0) {
        $("#vocab-tree").vocab_widget({
            mode: "tree",
            endpoint: "https://vocabs.ardc.edu.au/apps/vocab_widget/proxy/",
            repository: "anzsrc-for"
        });
    }
}

// add selected processing
function addSelectedTreeItem(modelName, fieldName, value, name) {
    var parentName = '.' + fieldName;
    if (isDuplicateSelection(parentName, value) === false) {
        var newItem = HandlebarsTemplates["dropdowns/item"]({
            field_name: fieldName,
            model_name: modelName,
            value: value,
            name: name
        })
        $(newItem).appendTo(parentName);
    }
}

// check to see if value has already been selected
function isDuplicateSelection(parentName, value) {
    var result = false;
    var parent = $(parentName);
    var children = parent.children();
    if (children && children.length > 0) {
        for (let i in children) {
            var child = children[i];
            if (child && child.tagName == "LI" && child.innerText) {
                //console.log('innerText[' + child.innerText + ']')
                if (child.innerText.trim() == value.trim()) {
                    result = true;
                    break;
                }
            }
        }
    }
    return result
}

// add an event listener
document.addEventListener("turbolinks:load", function () {
    // selected tree item
    $("#vocab-tree").on("treeselect.vocab.ands", function (event) {
        var data = $(event.target).data("vocab");
        if (data.label !== "") {
            var fieldName = $("#vocab-tree").attr("data-field");
            var modelName = $("#vocab-tree").attr("data-model");
            addSelectedTreeItem(modelName, fieldName, data.label, data.label);
        }
    })

})