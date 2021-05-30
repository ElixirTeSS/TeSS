var Fairsharing = {
    baseUrl: 'https://fairsharing.org',
    titleElement: function() {
        return $('#' + $('#title_element').val())
    },
    queryParameter: function() {
        return 'search=' + encodeURIComponent($('#fairsharing_query').val());
    },
    typeParameter: function() {
        var types = [];
        $(".bstype:checked").each(function () {
            types.push($(this).val());
        })
        if (types.length > 0) {
            return 'types=' + types.join();
        } else {
            return null;
        }
    },
    allTypeURL: function() {
        return Fairsharing.baseUrl + '/api/all/summary/';
    },
    websiteBaseURL: function(){
        return Fairsharing.baseUrl;
    },
    search: function(){
        $('.loading_image').show();
        Fairsharing.queryAPI(Fairsharing.allTypeURL() + '?' + Fairsharing.queryParameter() + '&' + Fairsharing.typeParameter());
    },
    nextPage: function(){
        var next = $('#fairsharing-next').text();
        if (next){
            $('.loading_image').show();
            Fairsharing.queryAPI(next);
        } else {
            /* display nice "we're out of stuff" message here */
            // console.log("No next URL found!");
        }
    },
    prevPage: function(){
        var prev = $('#fairsharing-previous').text();
        if (prev){
            $('.loading_image').show();
            Fairsharing.queryAPI(prev);
        } else {
            /* display nice "we're out of stuff" message here */
            // console.log("We're out of stuff!");
        }
    },
    queryAPI: function(api_url){
        $('.loading_image').show();
        var key = $('#fairsharing-api-key').text();
        $.ajax({url: api_url,
                type: 'GET',
                dataType: 'json',
                headers: {'Api-Key':key},
                contentType: 'application/json; charset=utf-8',
                success: function (result) {
                    $('.loading_image').hide();
                    Fairsharing.displayRecords(result);
                },
                error: function (error) {
                    // console.log("Error querying FAIRsharing: " + JSON.stringify(error));
                }
        });
    },
    associateTool: function(event){
        obj = $(event.target);
        ExternalResources.add(obj.data('title'), obj.data('url'));
        obj.parent().parent().fadeOut();
    },
    displayRecords: function(json){
        $('.loading_image').hide();
        $('#fairsharing-results').empty();
        var previous = json.previous;
        var next = json.next;
        if (previous) {
            if (previous.includes('page='))
            {
                $('#fairsharing-previous').text(previous);
                $('#prev-bs-button').show();
            } else {
                $('#prev-bs-button').hide();
            }
        } else {
            $('#prev-bs-button').hide();
        }
        if (next) {
            $('#fairsharing-next').text(next);
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
            var url = Fairsharing.websiteBaseURL() + '/' + id;
            if (item.type == 'policy') {
                var iconclass = "fa-institution";
            } else if (item.type == 'biodbcore') {
                var iconclass = "fa-database";
            } else {
                var iconclass = "fa-list-alt";
            }
            $('#fairsharing-results').append('' +
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
                '<span>' + truncateWithEllipses(item.description, 500)  + '</span>' +
                '<div class="external-links">' +
                '<a class="btn btn-warning" target="_blank" href="' + Fairsharing.websiteBaseURL() + '/' + id +'">' +
                'View ' + item.name + ' on FAIRsharing ' +
                '<i class="fa fa-external-link"/></a>' +
                '</div>' +
                '</div>');
        });
        $('#next-bs-button').attr('data-next', json.next);
    },
    copyTitleAndSearch: function(){
        $('#fairsharing_query').val(Fairsharing.titleElement().val());
        Fairsharing.search();
    },
    displayFullTool: function(api, id){
        var key = $('#fairsharing-api-key').text();
        var json_key = 'bsg_id';
        if (api.indexOf('policy') != -1) {
            var iconclass = "fa-institution";
        } else if (api.indexOf('database') != -1) {
            var iconclass = "fa-database";
            json_key = 'biodbcore_id';
        } else {
            var iconclass = "fa-list-alt";
        }

        $.ajax({url: api,
            type: 'GET',
            dataType: 'json',
            headers: {'Api-Key':key},
            contentType: 'application/json; charset=utf-8',
            success: function (result) {
                var json_object = result.data;
                $('#' + id + '-desc').text(json_object.description);
                $('#' + id + '-resource-type-icon').addClass(iconclass).removeClass('fa-external-link');
                $.each(json_object.domains, function(index, domain){
                    $('#' + id + '-topics').append(
                        '<span class="btn btn-default keyword-button">' +
                        domain +
                        '</span>'
                    );
                });
                $.each(json_object.taxonomies, function(index, taxonomy){
                    $('#' + id + '-topics').append(
                        '<span class="btn btn-default keyword-button">' +
                        taxonomy +
                        '</span>'
                    );
                });
                $('#' + id + '-external-links').append(
                    '<div>' +
                        '<a class="btn btn-success external-button" target="_blank" href="' + json_object.homepage +'">' +
                        'View the ' + json_object.name + ' homepage ' +
                        '<i class="fa fa-external-link"/></a>' +
                        '</a>' +
                        '<a class="btn btn-warning external-button" target="_blank" href="' + Fairsharing.websiteBaseURL() + '/' + json_object[json_key] +'">' +
                        'View ' + json_object.name + ' on FAIRsharing ' +
                        '<i class="fa fa-external-link"/></a>' +
                    '</div>'
                );
            },
            error: function (error) {
                // console.log("Error querying FAIRsharing: " + error);
            }
        });

    }
};

var delay = (function(){
    var timer = 0;
    return function(callback, ms){
        clearTimeout (timer);
        timer = setTimeout(callback, ms);
    };
})();

document.addEventListener("turbolinks:load", function() {
    $('.loading_image').hide();
    $('#next-bs-button').click(Fairsharing.nextPage);
    $('#prev-bs-button').click(Fairsharing.prevPage);
    $('#fairsharing_query').on({
        keyup: function () {
            delay(function () {
                Fairsharing.search();
            }, 1000);
        },
        keydown: function search(e) {
            if (e.keyCode === 13) {
                Fairsharing.search();
                e.preventDefault();
                return false;
            }
        }
    });
    $('#search_fairsharing').click(Fairsharing.search);
    $('#fairsharing-results').on('click','.associate-tool', Fairsharing.associateTool);
    $('#external-resources').on('change', '.delete-external-resource-btn input.destroy-attribute', ExternalResources.delete);
    Fairsharing.titleElement().blur(Fairsharing.copyTitleAndSearch);
});

