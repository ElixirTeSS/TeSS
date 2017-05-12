var TopicSuggestions = {
    accept: function(){
        var suggestion_info = $(this).parents('.suggestion_action');
        var url = "/" + suggestion_info.data('resource_type') + "/" + suggestion_info.data('resource_id') + "/add_topic"
        $.post(url, { topic: suggestion_info.data('topic')})
            .done(function( data ) {
                console.log("Added topic");
                /*Delete HTML*/
            });
    },
    reject: function(){
        var suggestion_info = $(this).parents('.suggestion_action');
        var url = "/" + suggestion_info.data('resource_type') + "/" + suggestion_info.data('resource_id') + "/reject_topic"
        $.post(url, { topic: suggestion_info.data('topic')})
            .done(function( data ) {
                console.log("Rejected topic")
                /*Delete HTML*/
        });
    }
}

$(document).ready(function () {
    $('.suggestion_action').on('click','.accept_suggestion', TopicSuggestions.accept);
    $('.suggestion_action').on('click','.reject_suggestion', TopicSuggestions.reject);
});
