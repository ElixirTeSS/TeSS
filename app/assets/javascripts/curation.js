const Curation = {
    applyParam: function (select, param) {
        const value = select.value;
        const url = new URL(window.location.href);
        if (!value) {
            url.searchParams.delete(param);
        } else {
            url.searchParams.set(param, value);
        }
        window.location.replace(url.toString());
    },

    curateUser: function (e) {
        e.preventDefault();
        const url = $(this).parents('.curate-user-buttons').data('actionUrl');
        const panel = $(this).parents('.curate-user');
        panel.fadeOut('fast');

        $.ajax({
            url: url,
            method: 'PUT',
            dataType: 'script',
            data: { user: { role_id: $(this).data('roleId') } }
        }).fail(function (e) {
            panel.show();
            console.error(e);
            alert('An error occurred while attempting to curate the user.');
        });

        return false;
    },

    init: function () {
        $('.curate-user-buttons .btn').click(Curation.curateUser);
    }
}
