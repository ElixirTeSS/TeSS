var Collaborations = {

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
    },

    add: function () {
        if (!$(this).hasClass('disabled')) {
            var url = $('#collaborators-modal').data('url');
            $.ajax({
                url: url,
                method: 'POST',
                data: { collaboration: { user_id: $('#collaborators-modal-add-id').val() } },
                success: function(collaboration) {
                    $('#collaborators-modal-add').val('');
                    $('#collaborators-modal-add-btn').addClass('disabled');
                    var element = $(HandlebarsTemplates['collaborations/collaboration'](collaboration)).addClass('new');
                    $('.collaboration-list').append(element);
                    Collaborations.displayEmptyText();
                }
            });
        }
    },

    displayEmptyText: function () {
        var list = $('.collaboration-list');
        if (!list.children('li').length) {
            list.append('<span class="empty">No collaborators</span>');
        } else {
            list.children('span').remove();
        }
    }
};
