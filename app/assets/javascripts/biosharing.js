var Biosharing = {
    baseUrl: 'https://dev.biosharing.org',
    titleElement: function() {
        return $('#' + $('#title_element').val())
    },
    queryParameter: function() {
        return 'search=' + encodeURIComponent($('#biosharing_query').val());
    },
    typeParameter: function() {
        var types = [];
        $(".bstype:checked").each(function () {
            types.push($(this).val());
        })
        console.log('types=' + types.join());
        if (types.length > 0) {
            return 'types=' + types.join();
        } else {
            return null;
        }
    },
    allTypeURL: function() {
        return Biosharing.baseUrl + '/api/all/summary';
    },
    websiteBaseURL: function(){
        return Biosharing.baseUrl;
    },
    search: function(){
        $('.loading_image').show();
        Biosharing.queryAPI(Biosharing.allTypeURL() + '?' + Biosharing.queryParameter() + '&' + Biosharing.typeParameter());
    },
    nextPage: function(){
        var next = $('#biosharing-next').text();
        if (next){
            $('.loading_image').show();
            Biosharing.queryAPI(next);
        } else {
            /* display nice "we're out of stuff" message here */
            console.log("No next URL found!");
        }
    },
    prevPage: function(){
        var prev = $('#biosharing-previous').text();
        if (prev){
            $('.loading_image').show();
            Biosharing.queryAPI(prev);
        } else {
            /* display nice "we're out of stuff" message here */
        }
    },
    queryAPI: function(api_url){
        $('.loading_image').show();
        console.log("Querying: " + api_url);
        var key = $('#biosharing-api-key').text();
        $.ajax({url: api_url,
                type: 'GET',
                dataType: 'json',
                headers: {'Api-Key':key},
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
        $('#biosharing-results').empty();
        var previous = json.previous;
        var next = json.next;
        if (previous) {
            if (previous.includes('page='))
            {
                $('#biosharing-previous').text(previous);
                $('#prev-bs-button').show();
            } else {
                $('#prev-bs-button').hide();
            }
        } else {
            $('#prev-bs-button').hide();
        }
        if (next) {
            $('#biosharing-next').text(next);
            $('#next-bs-button').show();
        } else {
            $('#next-bs-button').hide();
        }
        json.results.forEach(function(item,index) {
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
    /*
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
    */
};

$(document).ready(function () {
    $('#next-bs-button').click(Biosharing.nextPage);
    $('#prev-bs-button').click(Biosharing.prevPage);
    //$('#biosharing_query').keyup(Biosharing.search); // too many queries - please don't use this
    $('#search_biosharing').click(Biosharing.search);
    $('#biosharing-results').on('click','.associate-tool', Biosharing.associateTool);
    $('#external-resources').on('change', '.delete-external-resource-btn input.destroy-attribute', ExternalResources.delete);
    //Biosharing.titleElement().keyup(Biosharing.copyTitleAndSearch);
    //Biosharing.copyTitleAndSearch();
    Biosharing.queryAPI(Biosharing.allTypeURL() + '?' + Biosharing.typeParameter());
});