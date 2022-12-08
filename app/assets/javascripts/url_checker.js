var UrlChecker = {
    check: function () {
        var input = $(this);
        var body = {};
        var type = $(this).attr('name').split('[')[0];
        body[type] = { url: input.val() };
        var checkExistsUrl = $(this).data('urlCheck');
        var testValidUrl = $(this).data('urlValid');
        var url = input.val();

        $(this).addClass('loading');

        $.ajax({
            method: 'POST',
            dataType: 'json',
            url: checkExistsUrl,
            data: body,
            success: function (data, code, res) {
                if (data.id) {
                    input.parents('.form-group').removeClass('has-success has-error').addClass('has-warning');
                    input.siblings('.help-block').html(HandlebarsTemplates['url_checker/existing']({
                        title: data.title,
                        url: res.getResponseHeader('location')
                    }));

                    input.removeClass('loading');
                } else {
                    UrlChecker.validUrl(input, url, testValidUrl);
                }
            },
            complete: function () {
            }
        });
    },

    validUrl: function (input, url, endpoint) {
        $.ajax({
            dataType: 'json',
            url: endpoint,
            data: { url: url },
            success: function (data) {
                if (data.code === 200) {
                    input.parents('.form-group').removeClass('has-warning has-error').addClass('has-success');
                    input.siblings('.help-block').html('');
                } else {
                    input.parents('.form-group').removeClass('has-success has-warning').addClass('has-error');
                    input.siblings('.help-block').html(HandlebarsTemplates['url_checker/error'](data));
                }
            },
            complete: function () {
                input.removeClass('loading');
            }
        });
    }
};

document.addEventListener("turbolinks:load", function() {
    $('[data-url-check]').blur(UrlChecker.check);
});
