var TopicSuggestions = {
    accept: function(){
        var listing_div = $(this).parents('.list-group-item');
        var suggestion_info = $(this).parents('.suggestion_action');
        var all_suggestions = $(this).parents('.suggestions');
        var all_topics = listing_div.find('.scientific_topics');
        var dropdown_div = $(this).parents('.dropdown');
        var url = "/" + suggestion_info.data('resource_type') + "/" + suggestion_info.data('resource_id') + "/add_topic"
        $.post(url, { topic: suggestion_info.data('topic')})
            .done(function( data ) {
                /* Remove the suggestion and add the accepted topic to the list of scientific topics */
                dropdown_div.remove()
                if (listing_div.find('.scientific_topic').length == 0) {
                    all_topics.append('<b>Scientific topics: </b>')
                    all_topics.append('<span class=\"scientific_topic\"> ' + suggestion_info.data('topic') + '</span>')
                } else {
                    all_topics.append('<span class=\"scientific_topic\">, ' + suggestion_info.data('topic') + '</span>')
                }
                if (listing_div.find('.dropdown').length < 1){
                    all_suggestions.remove()
                }
            });
    },
    reject: function(){
        var suggestion_info = $(this).parents('.suggestion_action');
        var listing_div = $(this).parents('.list-group-item');
        var all_suggestions = $(this).parents('.suggestions');
        var dropdown_div = $(this).parents('.dropdown');
        var url = "/" + suggestion_info.data('resource_type') + "/" + suggestion_info.data('resource_id') + "/reject_topic"
        $.post(url, { topic: suggestion_info.data('topic')})
            .done(function( data ) {
                console.log("Rejected topic")
                dropdown_div.remove()
                if (listing_div.find('.dropdown').length < 1){
                    all_suggestions.remove()
                }
            });
    }
}

var DataSuggestions = {
    accept: function() {
        console.log("ACCEPTING!");
        var listing_div = $(this).parents('.list-group-item');
        var suggestion_info = $(this).parents('.data_suggestion_action');
        var all_suggestions = $(this).parents('.suggestions');
        var dropdown_div = $(this).parents('.dropdown');
        var data_field = suggestion_info.data('data_field');
        var data_value = suggestion_info.data('data_value');
        var url = "/" + suggestion_info.data('resource_type') + "/" + suggestion_info.data('resource_id') + "/add_data"
        $.post(url, { 'data_field' : data_field, 'data_value' : data_value })
            .done(function( data ) {
                /* Remove the suggestion and add the accepted topic to the list of scientific topics */
                dropdown_div.remove()
                /*
                // TODO: Add-code along these lines to update these fields.
                // TODO: event.show_map may need to be dealt with also
                if (listing_div.find('.scientific_topic').length == 0) {
                    all_topics.append('<b>Scientific topics: </b>')
                    all_topics.append('<span class=\"scientific_topic\"> ' + suggestion_info.data('topic') + '</span>')
                } else {
                    all_topics.append('<span class=\"scientific_topic\">, ' + suggestion_info.data('topic') + '</span>')
                }
                */
                if (listing_div.find('.dropdown').length < 1){
                    all_suggestions.remove()
                }
            });

    },
    reject: function() {
        console.log("REJECTING!");
        var suggestion_info = $(this).parents('.data_suggestion_action');
        var listing_div = $(this).parents('.list-group-item');
        var all_suggestions = $(this).parents('.suggestions');
        var dropdown_div = $(this).parents('.dropdown');
        var data_field = suggestion_info.data('data_field');
        var data_value = suggestion_info.data('data_value');
        var url = "/" + suggestion_info.data('resource_type') + "/" + suggestion_info.data('resource_id') + "/reject_data"
        $.post(url, { 'data_field' : data_field, 'data_value' : data_value })
            .done(function( data ) {
                console.log("Rejected data")
                dropdown_div.remove();
                if (listing_div.find('.dropdown').length < 1){
                    all_suggestions.remove()
                }
            });
    }
}

$(document).ready(function () {
    $('.suggestion_action').on('click','.accept_suggestion', TopicSuggestions.accept);
    $('.suggestion_action').on('click','.reject_suggestion', TopicSuggestions.reject);
    $('.data_suggestion_action').on('click','.accept_suggestion', DataSuggestions.accept);
    $('.data_suggestion_action').on('click','.reject_suggestion', DataSuggestions.reject);
});
