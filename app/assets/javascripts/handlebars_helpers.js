// A helper to iterate over a collection, but filter a given key "k" by value "v"
Handlebars.registerHelper('each_when', function(list, k, v, opts) {
    var i, result = '';
    for (i = 0; i < list.length; ++i) {
        if (list[i][k] == v) {
            result = result + opts.fn(list[i]);
        }
    }
    return result;
});

// A helper to check if there are any items in the collection with key "k" equal to value "v"
Handlebars.registerHelper('if_any', function(list, k, v, block) {
    var result = false;
    for (i = 0; i < list.length; ++i) {
        if(list[i][k] == v) {
            result = true;
            break;
        }
    }

    return result ? block.fn(this) : block.inverse(this);
});