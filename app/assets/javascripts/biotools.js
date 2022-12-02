var Biotools = {
    baseUrl: 'https://bio.tools',
    titleElement: function() {
        return $('#' + $('#title_element').val())
    },
    sortParameter: function() {
        return 'sort=score';
    },
    queryParameter: function() {
        return 'q=' + encodeURIComponent($('#tool_query').val());
    },
    perPage: function(){
        return 'per_page=5'
    },
    apiBaseURL: function(){
        return Biotools.baseUrl + '/api/tool';
    },
    websiteBaseURL: function(){
        return Biotools.baseUrl + '/tool';
    },
    search: function(){
        clearTimeout(Biotools._searchTimeout);

        Biotools._searchTimeout = setTimeout(function () {
            $('#biotools-results').empty();
            Biotools.queryAPI(Biotools.apiBaseURL() + '?' + Biotools.queryParameter() + '&' + Biotools.sortParameter());
        }, 500);
    },
    nextPage: function(){
        var next = $(this).data('page');
        if (next){
            Biotools.queryAPI(Biotools.apiBaseURL() + next + '&' + Biotools.queryParameter() + '&' + Biotools.sortParameter());
        }
    },
    queryAPI: function(api_url){
        $('#biotools-loading-spinner').show();
        $.ajax({
            url: api_url,
            type: 'GET',
            dataType: 'json',
            success: function (result) {
                Biotools.displayTools(result);
            },
            error: function (error) {
                console.log("Error querying bio.tools: " + JSON.stringify(error));
            },
            complete: function () {
                $('#biotools-loading-spinner').hide();
            }
        });
    },
    associateTool: function () {
        var obj = $(this);
        ExternalResources.add(obj.data('title'), obj.data('url'));
        obj.parents('#biotools-results div').fadeOut();
    },
    displayTools: function(json){
        json.list.forEach(function (item) {
            $('#biotools-results').append(HandlebarsTemplates['external_resources/search_result']({
                name: item.name,
                url: Biotools.websiteBaseURL() + '/' + item.biotoolsID,
                description: item.description,
                truncatedDescription: truncateWithEllipses(item.description, 200),
                labels: item.toolType,
                siteName: 'bio.tools',
                iconClass: 'fa fa-wrench'
            }));
        });
        if (json.next) {
            $('#next-tools-button').data('page', json.next).show();
        } else {
            $('#next-tools-button').hide();
        }
    },
    copyTitleAndSearch: function(){
        $('#tool_query').val(Biotools.titleElement().val());
        Biotools.search();
    },
    displayToolInfo: function(id){
        $.getJSON((Biotools.apiBaseURL() + '/' + id), function(data){
            var res = {};
            res['topics'] = [];
            $.each(data.topic, function(index, topic) {
                res['topics'].push('<a href="' + topic.uri +'" class="label label-default filter-button">' + topic.term + '</a>');
            });
            $('#tool-topics-' + id).html('<div>' + res['topics'].join(' ') + '</div>')
            $('#tool-description-' + id).html(data.description)
            return res
        })
    },
    displayFullTool: function(api, id){
        $.get(api, function(json_object) {
            $('#' + id + '-desc').text(json_object.description);
            $('#' + id + '-resource-type-icon').addClass('fa-wrench').removeClass('fa-external-link');
            $.each(json_object.toolType, function(index, ttype){
                $('#' + id + '-types').append(
                    '<span class="label label-info typelabel">' +
                    ttype +
                    '</span>'
                );
            });
            $.each(json_object.topic, function(index, topic){
                $('#' + id + '-topics').append(
                    '<span class="btn btn-default keyword-button">' +
                    '<a href="' + topic.uri + '" target="_blank">' + topic.term + '</a>' +
                    '</span>'
                );
            });
            $('#' + id + '-external-links').append(
                '<div>' +
                '<a class="btn btn-success external-button" target="_blank" rel="noopener" href="' + json_object.homepage +'">' +
                'View the ' + json_object.name + ' homepage ' +
                '<i class="fa fa-external-link"></i></a>' +
                '</a>' +
                '<a class="btn btn-warning external-button" target="_blank" rel="noopener" href="' + Biotools.websiteBaseURL() + '/' + json_object.biotoolsID +'">' +
                'View ' + json_object.name + ' on bio.tools ' +
                '<i class="fa fa-external-link"></i></a>' +
                '</div>'
            );
        }, 'json');
    },

    init: function () {
        var delay = function () {
            var timer = 0;
            return function(callback, ms){
                clearTimeout (timer);
                timer = setTimeout(callback, ms);
            };
        }();

        $('#next-tools-button').click(Biotools.nextPage);
        $('#tool_query').on({
            keyup: function () {
                delay(function () {
                    Biotools.search();
                }, 300);
            },
            keydown: function search(e) {
                if (e.keyCode === 13) {
                    Biotools.search();
                    e.preventDefault();
                    return false;
                }
            }
        });
        $('#search_tools').click(Biotools.search);
        $('#biotools-results').on('click', '.associate-tool', Biotools.associateTool);
        $('#external-resources').on('change', '.delete-external-resource-btn input.destroy-attribute', ExternalResources.delete);

        if ($('#tool_query').length) {
            Biotools.titleElement().keyup(Biotools.copyTitleAndSearch);
            Biotools.copyTitleAndSearch();
        }
    }
};
