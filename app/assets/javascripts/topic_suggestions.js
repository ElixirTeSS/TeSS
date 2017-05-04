var TopicSuggestions = {
    accept: function(){
        var suggestion_info = $(this).parents('.suggestion_action');
        console.log()
        console.log(suggestion_info.data('resource_id'))
        console.log(suggestion_info.data('topic'))
        var url = "/" + suggestion_info.data('resource_type') + "/" + suggestion_info.data('resource_id') + "/add_topic"

        $.post(url, { topic: suggestion_info.data('topic')})
            .done(function( data ) {
                alert( "Donion rings " + data );
            });
    },
    reject: function(){
        
    }
}


$(document).ready(function () {
    $('.suggestion_action').on('click','.accept_suggestion', TopicSuggestions.accept);
});
