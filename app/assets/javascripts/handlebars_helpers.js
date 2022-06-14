// A helper to iterate over a collection, but filter a given key "k" by value "v"
Handlebars.registerHelper("each_when", function(list, k, v, opts) {
    var i, result = "";
    for (i = 0; i < list.length; ++i) {
        if (list[i][k] == v) {
            result = result + opts.fn(list[i]);
        }
    }
    return result;
});

// A helper to check if there are any items in the collection with key "k" equal to value "v"
Handlebars.registerHelper("if_any", function(list, k, v, block) {
    var result = false;
    for (var i = 0; i < list.length; ++i) {
        if(list[i][k] == v) {
            result = true;
            break;
        }
    }

    return result ? block.fn(this) : block.inverse(this);
});

var months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October",
    "November", "December"];

Handlebars.registerHelper("formatDate", function(stringDate){
    var date = new Date(stringDate.substr(0, stringDate.length-5));
    var day = date.getDate();
    var month = date.getMonth();
    var year = date.getFullYear();
    return (day+ " " + months[month] + ", " + year);
})

/* Todo: Finish off nice date range formatting in jquery */
Handlebars.registerHelper("formatDateRange", function(startDate, endDate){
    var start = new Date(startDate.substr(0, startDate.length-5));
    var end = new Date(endDate.substr(0, endDate.length-5));

    var day = date.getDate();
    var month = date.getMonth();
    var year = date.getFullYear();
    return (day+ " " + months[month] + ", " + year);
})
