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

var months = ["January", "February", "March",
    "April", "May", "June", "July", "August", "September",
    "October", "November", "December"];


Handlebars.registerHelper('formatDate', function(string_date){
    var date = new Date(string_date.substr(0, string_date.length-5));
    var day = date.getDate();
    var month = date.getMonth();
    var year = date.getFullYear();
    return (day+ " " + months[month] + ", " + year);
})


/* Todo: Finish off nice date range formatting in jquery */
Handlebars.registerHelper('formatDateRange', function(start_date, end_date){
    var start = new Date(start_date.substr(0, start_date.length-5));
    var end = new Date(end_date.substr(0, end_date.length-5));

    if (start.getDate() == end.getDate()){

    } else {

    }
    var day = date.getDate();
    var month = date.getMonth();
    var year = date.getFullYear();
    return (day+ " " + months[month] + ", " + year);
})
