var Biosharing = {
    baseUrl: 'https://dev.biosharing.org',
    titleElement: function() {
        return $('#' + $('#title_element').val())
    },
    /*
    sortParameter: function() {
        return 'sort=score';
    },
    */
    queryParameter: function() {
        return 'search=' + encodeURIComponent($('#biosharing_query').val());
    },
    allTypeURL: function() {
        return Biosharing.baseUrl + '/api/all/summary';
    },
    /*
    apiBaseURL: function(){
        return Biosharing.baseUrl + '/api/tool';
    },
     */
    websiteBaseURL: function(){
        return Biosharing.baseUrl;
    },
    search: function(){
        $('#biosharing-results').empty();
        $('.loading_image').show();
        Biosharing.queryAPI(Biosharing.allTypeURL() + '?' + Biosharing.queryParameter());
    },
    nextPage: function(){
        var next_page = $(event.target).attr('data-next');
        if (next_page){
            Biosharing.queryAPI(Biosharing.allTypeURL() + next_page + '&' + Biosharing.queryParameter());
        } else {
            /* display nice "we're out of stuff" message here */
        }
    },
    queryAPI: function(api_url){
        $('.loading_image').show();
        $.ajax({url: api_url,
                type: 'GET',
                dataType: 'json',
                headers: {'Api-Key':'7f1af03ac7aec02b572656550f37d2f1e8f77b7b'},
                contentType: 'application/json; charset=utf-8',
                success: function (result) {
                    $('.loading_image').hide();
                    Biosharing.displayRecords(result);
                },
                error: function (error) {
                    console.log("Error querying BioSharing: " + error);
                }
        });
    },
    associateTool: function(event){
        obj = $(event.target);
        ExternalResources.add(obj.data('title'), obj.data('url'));
        obj.parent().parent().fadeOut();
    },
    displayRecords: function(json){
        json.results.forEach(function(item,index) {
            console.log("ITEM: " + index + " => " + item);
            if (item.biodbcore_id) {
                var id = item.biodbcore_id;
            } else {
                var id = item.bsg_id;
            }
            var url = Biosharing.websiteBaseURL() + '/' + id;
            if (item.type == 'policy') {
                var iconclass = "fa-institution";
            } else if (item.type == 'biodbcore') {
                var iconclass = "fa-database";
            } else {
                var iconclass = "fa-list-alt";
            }
            $('#biosharing-results').append('' +
                '<div id="' + id + '" class="col-md-12 col-sm-12 bounding-box" data-toggle=\"tooltip\" data-placement=\"top\" aria-hidden=\"true\" title=\"' + item.description + '\">' +
                '<h4>' +
                '<i class="fa ' +  iconclass + '"></i> ' +
                '<a href="' + url + '">' +
                '<span class="title">' +
                item.name +
                '</span>' +
                '</a>' +
                ' <i id="' + id + '" ' +
                'class="fa fa-plus-square-o associate-tool"/ ' +
                'title="click to associate ' + item.name + ' with this resource"' +
                'data-title="' + item.name + '" data-url="' + url + '"/>' +
                '</h4>' +
                '<span>' + item.description + '</span>' +
                '<div class="external-links">' +
                '<a class="btn btn-warning" target="_blank" href="' + Biosharing.websiteBaseURL() + '/' + id +'">' +
                'View ' + item.name + ' on BioSharing ' +
                '<i class="fa fa-external-link"/></a>' +
                '</div>' +
                '</div>');
        });
        $('#next-tools-button').attr('data-next', json.next);
    },
    copyTitleAndSearch: function(){
        $('#biosharing_query').val(Biosharing.titleElement().val());
        Biosharing.search();
    },
    displayToolInfo: function(id){
        var res = {};
        $.getJSON((Biosharing.apiBaseURL() + '/' + id), function(data){
            var res = {};
            res['topics'] = [];
            $.each(data.topic, function(index, topic){
                console.log(topic)
                res['topics'].push('<a href="' + topic.uri +'" class="label label-default filter-button">' + topic.term + '</a>');
            });
            $('#tool-topics-' + id).html('<div>' + res['topics'].join(' ') + '</div>')
            $('#tool-description-' + id).html(data.description)
            return res
        })
    },
    displayFullTool: function(api, id){
        var json = $.get(api, function(json) {
            var json_object = json;
            $('#' + id + '-desc').text(json_object.description);
            $('#' + id + '-resource-type-icon').addClass('fa-wrench').removeClass('fa-external-link');
            $.each(json_object.topic, function(index, topic){
                $('#' + id + '-topics').append(
                    '<span class="btn btn-default keyword-button">' +
                    '<a href="' + topic.uri + '" target="_blank">' + topic.term + '</a>' +
                    '</span>'
                );
            });
            $('#' + id + '-external-links').append(
                '<div>' +
                '<a class="btn btn-success" target="_blank" href="' + json_object.homepage +'">' +
                'View the ' + json_object.name + ' homepage ' +
                '<i class="fa fa-external-link"/></a>' +
                '</a>' +
                '<a class="btn btn-warning" target="_blank" href="' + Biosharing.websiteBaseURL() + '/' + json_object.id +'">' +
                'View ' + json_object.name + ' on bio.tools ' +
                '<i class="fa fa-external-link"/></a>' +
                '</div>'
            );
        });
    }
};

$(document).ready(function () {
    $('#next-tools-button').click(Biosharing.nextPage);
    //$('#biosharing_query').keyup(Biosharing.search); // too many queries
    $('#search_biosharing').click(Biosharing.search);
    $('#biosharing-results').on('click','.associate-tool', Biosharing.associateTool);
    $('#external-resources').on('change', '.delete-external-resource-btn input.destroy-attribute', ExternalResources.delete);
    Biosharing.titleElement().keyup(Biosharing.copyTitleAndSearch);
    Biosharing.copyTitleAndSearch();
    Biosharing.queryAPI(Biosharing.allTypeURL());
    //Biosharing.queryAPI(Biosharing.apiBaseURL() + '?' + Biosharing.queryParameter() + '&' + Biosharing.sortParameter());
});