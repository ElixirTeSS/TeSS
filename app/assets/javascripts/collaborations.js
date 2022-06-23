var Collaborations = {
    init: function () {
        $('.collaboration-list').on('click', '.delete-collaboration', Collaborations.delete);
        $('#collaborators-modal').on('show.bs.modal', Collaborations.fetch);

        $('#collaborators-modal-add').autocomplete({
            lookup: function (query, done) {
                var url = $('#collaborators-modal').data('queryUrl');
                $.ajax({
                    url: url.replace('-query-', query),
                    dataType: 'json',
                    success : function(data) {
                        done(Autocompleters.transformFunctions.users(data, { idField: 'id' }));
                    }
                });
            },
            onSelect: function (suggestion) {
                Collaborations.add(suggestion.data)
                $(this).val('').focus();
            }
        });
    },

    fetch: function () {
        var url = $('#collaborators-modal').data('url');
        $.ajax({
            url: url,
            success : function(data) {
                $('.collaboration-list').html('');
                data.forEach(function (collaboration) {
                    $('.collaboration-list').append(HandlebarsTemplates['collaborations/collaboration'](collaboration));
                });
                Collaborations.displayEmptyText();
            }
        });
    },

    delete: function () {
        var url = $('#collaborators-modal').data('url');
        var element = $(this).parent('li');

        $.ajax({
            url: url + '/' + element.data('id'),
            dataType: 'json',
            method: 'DELETE',
            success: function() {
                element.remove();
                Collaborations.displayEmptyText();
            }
        });

        return false;
    },

    add: function (id) {
        var url = $('#collaborators-modal').data('url');
        $.ajax({
            url: url,
            method: 'POST',
            data: { collaboration: { user_id: id } },
            success: function(collaboration) {
                $('#collaborators-modal-add').val('');
                $('#collaborators-modal-add-btn').addClass('disabled');
                var element = $(HandlebarsTemplates['collaborations/collaboration'](collaboration)).addClass('new');
                $('.collaboration-list').append(element);
                Collaborations.displayEmptyText();
            }
        });
    },

    displayEmptyText: function () {
        var list = $('.collaboration-list');
        if (!list.children('li').length) {
            if (!$('span.empty', list).length) {
                list.append('<span class="empty">No collaborators</span>');
            }
        } else {
            list.children('span').remove();
        }
    }
};
