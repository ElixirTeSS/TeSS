var LearningPaths = {
    init: function () {
        $('.learning-path-topic-title').click(function () {
            const container = $(this).closest('.learning-path-topic');
            const contents = container.find('.learning-path-topic-contents');
            $(this).find('.expand-icon, .collapse-icon').toggleClass('collapse-icon').toggleClass('expand-icon');
            contents.slideToggle();
        });

        if (window.location.hash) {
            var topic = $('.learning-path-topic' + window.location.hash);
            if (topic.length) {
                $('.learning-path-topic-title', topic).click();
            }
        }
    }
}
