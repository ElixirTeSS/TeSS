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

        $("[data-role='user-lp-topics-select']").change(LearningPaths.selectTopic);
    },

    selectTopic: function () {
        const element = $(this);
        const option = $(this).find('option:selected');
        const id = parseInt(option.val());
        if (!id) {
            return true;
        }
        const title = option.text();
        const listElement = $("[data-role='collection-items-group']").find('.collection-items');
        if (!$("[data-id='Topic-" + id + "']", listElement).length) {
            const obj = { item: {
                    id: null,
                    title: title,
                    url: option.data('url'),
                    resource_id: id,
                    resource_type: 'Topic'
                },
                prefix: 'learning_path[topic_links_attributes]'
            };

            listElement.append(HandlebarsTemplates['autocompleter/learning_path_topic'](obj));
            const event = new CustomEvent('autocompleters:added', {  bubbles: true, detail: { object: obj } });
            listElement[0].dispatchEvent(event);
        }

        element.val('').focus();
    }
}
