var TermSuggestions = {
    accept: function(){
        var listing_div = $(this).parents('.list-group-item');
        var suggestion_info = $(this).parents('.suggestion_action');
        var term_suggestions = $(this).parents('.term_suggestions');
        var dropdown_div = $(this).parents('.dropdown');
        var url = "/" + suggestion_info.data('resource_type') + "/" + suggestion_info.data('resource_id') + "/add_term";
        $.post(url,
            {
                uri: suggestion_info.data('uri'),
                field: suggestion_info.data('field')
            })
            .done(function(data) {
                var field = suggestion_info.data('field');
                var all_terms = listing_div.find('.' + field);

                /* Remove the suggestion and add the accepted topic to the list of scientific topics */
                var singularField = field.slice(0, -1);
                var title = field.charAt(0).toUpperCase() + field.slice(1).replace(/_/gi, ' ');
                dropdown_div.remove();
                var firstTerm = listing_div.find('.' + singularField).length === 0;
                if (firstTerm) {
                    all_terms.append('<b>' + title + ': </b>');
                } else {
                    all_terms.append(', ');
                }

                all_terms.append('<span class=\"' + singularField + '\"> ' + suggestion_info.data('label') + '</span>');
                if (term_suggestions.find('.dropdown').length < 1){
                    term_suggestions.remove();
                }
            });
    },
    reject: function(){
        var suggestion_info = $(this).parents('.suggestion_action');
        var listing_div = $(this).parents('.list-group-item');
        var term_suggestions = $(this).parents('.term_suggestions');
        var dropdown_div = $(this).parents('.dropdown');
        var url = "/" + suggestion_info.data('resource_type') + "/" + suggestion_info.data('resource_id') + "/reject_term";
        $.post(url, {
            uri: suggestion_info.data('uri'),
            field: suggestion_info.data('field')
        })
            .done(function( data ) {
                console.log("Rejected term");
                dropdown_div.remove();
                if (term_suggestions.find('.dropdown').length < 1){
                    term_suggestions.remove();
                }
            });
    }
};

var DataSuggestions = {
    accept: function() {
        var suggestion_info = $(this).parents('.data_suggestion_action');
        var data_suggestions = $(this).parents('.data_suggestions');
        var dropdown_div = $(this).parents('.dropdown');
        var data_field = suggestion_info.data('data_field');
        var url = "/" + suggestion_info.data('resource_type') + "/" + suggestion_info.data('resource_id') + "/add_data";
        $.post(url, { 'data_field' : data_field })
            .done(function( data ) {
                /* Remove the suggestion and add the data to the relevant field */
                dropdown_div.remove();
                console.log("Removed: " + dropdown_div);
                if (data_suggestions.find('.dropdown').length < 1){
                    data_suggestions.remove();
                    console.log("(2)Removed: " + data_suggestions);
                }
            });

    },
    reject: function() {
        var suggestion_info = $(this).parents('.data_suggestion_action');
        var data_suggestions = $(this).parents('.data_suggestions');
        var dropdown_div = $(this).parents('.dropdown');
        var data_field = suggestion_info.data('data_field');
        var url = "/" + suggestion_info.data('resource_type') + "/" + suggestion_info.data('resource_id') + "/reject_data";
        $.post(url, { 'data_field' : data_field })
            .done(function( data ) {
                console.log("Rejected data");
                dropdown_div.remove();
                if (data_suggestions.find('.dropdown').length < 1){
                    data_suggestions.remove();
                }
            });
    }
};

document.addEventListener("turbolinks:load", function() {
    $('.suggestion_action').on('click','.accept_suggestion', TermSuggestions.accept);
    $('.suggestion_action').on('click','.reject_suggestion', TermSuggestions.reject);
    $('.data_suggestion_action').on('click','.accept_suggestion', DataSuggestions.accept);
    $('.data_suggestion_action').on('click','.reject_suggestion', DataSuggestions.reject);
});
