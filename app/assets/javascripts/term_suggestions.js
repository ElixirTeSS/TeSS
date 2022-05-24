var TermSuggestions = {
    accept: function(){
        var listingDiv = $(this).parents(".list-group-item");
        var suggestionInfo = $(this).parents(".suggestion_action");
        var termSuggestions = $(this).parents(".term_suggestions");
        var dropdownDiv = $(this).parents(".dropdown");
        var url = "/" + suggestionInfo.data("resource_type") + "/" + suggestionInfo.data("resource_id") + "/add_term";
        $.post(url,
            {
                uri: suggestionInfo.data("uri"),
                field: suggestionInfo.data("field")
            })
            .done(function(data) {
                var field = suggestionInfo.data("field");
                var allTerms = listingDiv.find("." + field);

                /* Remove the suggestion and add the accepted topic to the list of scientific topics */
                var singularField = field.slice(0, -1);
                var title = field.charAt(0).toUpperCase() + field.slice(1).replace(/_/gi, " ");
                dropdownDiv.remove();
                var firstTerm = listingDiv.find("." + singularField).length === 0;
                if (firstTerm) {
                    allTerms.append("<b>" + title + ": </b>");
                } else {
                    allTerms.append(", ");
                }

                allTerms.append('<span class=\"' + singularField + '\"> ' + suggestionInfo.data('label') + '</span>');
                if (termSuggestions.find(".dropdown").length < 1){
                    termSuggestions.remove();
                }
            });
    },
    reject: function(){
        var suggestionInfo = $(this).parents(".suggestion_action");
        var listingDiv = $(this).parents(".list-group-item");
        var termSuggestions = $(this).parents(".term_suggestions");
        var dropdownDiv = $(this).parents(".dropdown");
        var url = "/" + suggestionInfo.data("resource_type") + "/" + suggestionInfo.data("resource_id") + "/reject_term";
        $.post(url, {
            uri: suggestionInfo.data("uri"),
            field: suggestionInfo.data("field")
        })
            .done(function( data ) {
                // console.log("Rejected term");
                dropdownDiv.remove();
                if (termSuggestions.find(".dropdown").length < 1){
                    termSuggestions.remove();
                }
            });
    }
};

var DataSuggestions = {
    accept: function() {
        var suggestionInfo = $(this).parents(".data_suggestion_action");
        var dataSuggestions = $(this).parents(".data_suggestions");
        var dropdownDiv = $(this).parents(".dropdown");
        var dataField = suggestionInfo.data("data_field");
        var url = "/" + suggestionInfo.data("resource_type") + "/" + suggestionInfo.data("resource_id") + "/add_data";
        $.post(url, { "data_field" : dataField })
            .done(function( data ) {
                /* Remove the suggestion and add the data to the relevant field */
                dropdownDiv.remove();
                // console.log("Removed: " + dropdownDiv);
                if (dataSuggestions.find(".dropdown").length < 1){
                    dataSuggestions.remove();
                    // console.log("(2)Removed: " + dataSuggestions);
                }
            });

    },
    reject: function() {
        var suggestionInfo = $(this).parents(".data_suggestion_action");
        var dataSuggestions = $(this).parents(".data_suggestions");
        var dropdownDiv = $(this).parents(".dropdown");
        var dataField = suggestionInfo.data("data_field");
        var url = "/" + suggestionInfo.data("resource_type") + "/" + suggestionInfo.data("resource_id") + "/reject_data";
        $.post(url, { "data_field" : dataField })
            .done(function( data ) {
                // console.log("Rejected data");
                dropdownDiv.remove();
                if (dataSuggestions.find(".dropdown").length < 1){
                    dataSuggestions.remove();
                }
            });
    }
};

document.addEventListener("turbolinks:load", function() {
    $(".suggestion_action").on("click",".accept_suggestion", TermSuggestions.accept);
    $(".suggestion_action").on("click",".reject_suggestion", TermSuggestions.reject);
    $(".data_suggestion_action").on("click",".accept_suggestion", DataSuggestions.accept);
    $(".data_suggestion_action").on("click",".reject_suggestion", DataSuggestions.reject);
});
