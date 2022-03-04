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

// check to see if value has already been selected
function isDuplicateSelection(parentName, value) {
    var result = false;
    var parent = $(parentName);
    var children = parent.children();
    if (children && children.length > 0) {
        for (let i in children) {
            if (children[i]
                && children[i].tagName === "LI"
                && children[i].innerText) {
                if (children[i].innerText.trim() === value.trim()) {
                    result = true;
                    break;
                }
            }
        }
    }
    return result;
};

// add selected processing
function addSelectedTreeItem(modelName, fieldName, dataValue, dataName) {
    var parentName = "." + fieldName;
    if (isDuplicateSelection(parentName, dataValue) === false) {
        var newItem = HandlebarsTemplates["dropdowns/item"]({
            field_name: fieldName,
            model_name: modelName,
            value: dataValue,
            name: dataName
        })
        $(newItem).appendTo(parentName);
    }
};

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