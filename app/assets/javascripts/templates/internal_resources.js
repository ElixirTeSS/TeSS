var record_type = null;
var InternalResources = {
    queryParameter: function() {
        return 'q=' + encodeURIComponent($('#materials_query').val());
    },
    search: function(type){
        record_type = type;
        $('.loading_image').show();
        var url = '/' + record_type;
        InternalResources.queryAPI(url + '?' + InternalResources.queryParameter(), record_type);
    },
    nextPage: function(){
        var next = $('#materials-next').text();
        if (next){
            $('.loading_image').show();
            InternalResources.queryAPI(next);
        } else {
            /* display nice "we're out of stuff" message here */
            console.log("No next URL found!");
        }
    },
    queryAPI: function(url){
        console.log("QUERYING: " + url);
        $('.loading_image').show();
        $.ajax({url: url,
            type: 'GET',
            dataType: 'json',
            headers: {'Accept': 'application/vnd.api+json'},
            contentType: 'application/json; charset=utf-8',
            success: function (result) {
                $('.loading_image').hide();
                InternalResources.displayRecords(result);
            },
            error: function (error) {
                console.log("Error querying TeSS for " + record_type + ": " + error);
            }
        });

    },
    displayRecords: function(json){
        $('#materials-results').empty();
        // TODO: Fix this using the relevant API info:
        // TODO: https://app.swaggerhub.com/apis/fbacall/TeSS-JSON-API/0.2.0#/materials/get_materials
        /*
        var previous = json.previous;
        var next = json.next;
        if (previous) {
            if (previous.includes('page='))
            {
                $('#materials-previous').text(previous);
                $('#prev-materials-button').show();
            } else {
                $('#prev-materials-button').hide();
            }
        } else {
            $('#prev-materials-button').hide();
        }
        if (next) {
            $('#materials-next').text(next);
            $('#next-materials-button').show();
        } else {
            $('#next-materials-button').hide();
        }
        */
        console.log("JSON: " + JSON.stringify(json));
        json.data.forEach(function(item, index) {
            var url = '/' + record_type + '/';
            // TODO: Come up with some decent icon choices here...
            if (record_type == 'materials') {
                var iconclass = "fa-list-alt";
            } else {
                var iconclass = "fa-list-alt";
            }
            $('#materials-results').append('' +
                '<div id="' + item.id + '" class="col-md-12 col-sm-12 bounding-box" data-toggle=\"tooltip\" data-placement=\"top\" aria-hidden=\"true\" title=\"' + item.attributes['short-description'] + '\">' +
                '<h4>' +
                '<i class="fa ' +  iconclass + '"></i> ' +
                '<a href="' + url + '">' +
                '<span class="title">' +
                item.attributes.title +
                '</span>' +
                '</a>' +
                ' <i id="' + item.id + '" ' +
                'class="fa fa-plus-square-o associate-tool"/ ' +
                'title="click to associate ' + item.attributes.title + ' with this resource"' +
                'data-title="' + item.attributes.title + '" data-url="' + url + '"/>' +
                '</h4>' +
                '<span>' + item.attributes['short-description'] + '</span>' +
                '<div class="external-links">' +
                '<a class="btn btn-warning" target="_blank" href="' + url + item.id +'">' +
                'View ' + '<i class="fa fa-external-link"/></a>' +
                '</div>' +
                '</div>');
        });
        $('#next-materials-button').attr('data-next', json.next);
    },

};

function delete_internal_resource(id) {
    $('#' + id).remove();
}

$(document).ready(function () {
    $(document).on('click', '.delete-internal-resource', function () {
        return false;
    });
    $('.loading_image').hide();
    //$('#search_materials').click(InternalResources.search('materials'));
});
