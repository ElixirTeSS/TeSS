const Sources = {
    checkStatus: function (jobId) {
        const spinner = $('#test-spinner');
        $.ajax({
            dataType: 'json',
            url: $('#test-btn').data('jobStatusUrl'),
            data: { id: jobId },
            success: function (data) {
                if (data.status === 'complete') {
                    $('#test-status').text('Fetching results');
                    $.ajax({
                        dataType: 'html',
                        url: $('#test-results').data('resultsUrl'),
                        success: function (html) {
                            $('#test-status').text('');
                            $('#test-results').hide().html(html).fadeIn();
                            $('#test-btn').removeClass('disabled');
                        },
                        error: function (data) {
                            console.log('error', data);
                            $('#test-status').text('');
                            $('#test-errors').show().text('There was a problem rendering the results.');
                        },
                        complete: function () {
                            spinner.hide();
                        }
                    });
                } else if (data.status === 'working') {
                    $('#test-status').text('Running test');
                    setTimeout(function () { Sources.checkStatus(jobId) }, 2000);
                } else if (data.status === 'queued') {
                    $('#test-status').text('Waiting for test to begin');
                    setTimeout(function () { Sources.checkStatus(jobId) }, 2000);
                } else if (data.status === 'retrying') {
                    $('#test-status').text('A problem occurred, retrying');
                    setTimeout(function () { Sources.checkStatus(jobId) }, 2000);
                } else {
                    console.log('bad job response', data);
                    $('#test-status').text('');
                    $('#test-errors').text('There was a problem testing the source. Please check the URL is correct and the appropriate method is selected. Job ' + data.status).show();
                    spinner.hide();
                }
            },
            error: function (data) {
                console.log('error', data);
                $('#test-status').text('');
                $('#test-errors').text('There was a problem getting the job status');
                spinner.hide();
            }
        });
    },

    startTest: function () {
        const btn = $(this);
        if (btn.hasClass('disabled')) {
            return false;
        }

        btn.addClass('disabled');
        $('#test-spinner').show();
        $('#test-errors').hide().text('');
        $('#test-status').text('Submitting job');

        $.ajax({
            dataType: 'json',
            url: btn.data('testUrl'),
            method: 'POST',
            success: function (data) {
                const jobId = data.id;
                $('#test-status').text('Waiting for status');
                Sources.checkStatus(jobId);
            },
            error: function (data) {
                console.log('error', data);
                $('#test-status').text('');
                $('#test-errors').text('There was a problem creating the test job: ' + data.responseText);
                $('#test-spinner').hide();
            }
        });

        return false;
    },
    init: function () {
        const btn = $('#test-btn');
        btn.click(Sources.startTest)
        if (btn.data('testJobId')) {
            Sources.checkStatus(btn.data('testJobId'));
            $('#test-spinner').show();
            btn.addClass('disabled');
        }
    }
};
