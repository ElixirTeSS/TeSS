var TopicSuggestions = {
    accept: function(){
        var listing_div = $(this).parents('.list-group-item');
        var suggestion_info = $(this).parents('.suggestion_action');
        var topic_suggestions = $(this).parents('.topic_suggestions');
        var all_topics = listing_div.find('.scientific_topics');
        var dropdown_div = $(this).parents('.dropdown');
        var url = "/" + suggestion_info.data('resource_type') + "/" + suggestion_info.data('resource_id') + "/add_term";
        $.post(url,
            {
                uri: suggestion_info.data('uri'),
                field: suggestion_info.data('field')
            })
            .done(function( data ) {
                /* Remove the suggestion and add the accepted topic to the list of scientific topics */
                dropdown_div.remove();
                if (listing_div.find('.scientific_topic').length == 0) {
                    all_topics.append('<b>Scientific topics: </b>');
                    all_topics.append('<span class=\"scientific_topic\"> ' + suggestion_info.data('label') + '</span>');
                } else {
                    all_topics.append('<span class=\"scientific_topic\">, ' + suggestion_info.data('label') + '</span>');
                }
                if (topic_suggestions.find('.dropdown').length < 1){
                    topic_suggestions.remove();
                }
            });
    },
    reject: function(){
        var suggestion_info = $(this).parents('.suggestion_action');
        var listing_div = $(this).parents('.list-group-item');
        var topic_suggestions = $(this).parents('.topic_suggestions');
        var dropdown_div = $(this).parents('.dropdown');
        var url = "/" + suggestion_info.data('resource_type') + "/" + suggestion_info.data('resource_id') + "/reject_term";
        $.post(url, { topic: suggestion_info.data('topic')})
            .done(function( data ) {
                console.log("Rejected topic");
                dropdown_div.remove();
                if (topic_suggestions.find('.dropdown').length < 1){
                    topic_suggestions.remove();
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

$(document).ready(function () {
    $('.suggestion_action').on('click','.accept_suggestion', TopicSuggestions.accept);
    $('.suggestion_action').on('click','.reject_suggestion', TopicSuggestions.reject);
    $('.data_suggestion_action').on('click','.accept_suggestion', DataSuggestions.accept);
    $('.data_suggestion_action').on('click','.reject_suggestion', DataSuggestions.reject);
});
