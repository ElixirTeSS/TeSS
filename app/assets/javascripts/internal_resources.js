var record_type = null;
var current_page = 1;
var default_length = 30;
var InternalResources = {
    queryParameter: function() {
        if ($('#materials_query').val()) {
            return '?q=' + encodeURIComponent($('#materials_query').val());
        } else {
            return '?q=';
        }
    },
    getUrl: function() {
        var url = '/' + record_type + InternalResources.queryParameter();
        return url;
    },
    search: function(type) {
        //console.log(">>> search: " + type)
        record_type = type;
        $('.loading_image').show();
        InternalResources.queryAPI(InternalResources.getUrl());
    },
    nextPage: function(){
        var next = $('#materials-next').text();
        if (next){
            $('.loading_image').show();
            current_page = current_page + 1;
            InternalResources.queryAPI(InternalResources.getUrl() + '&page_number=' + next);
        } else {
            // console.log("No next URL found!");
        }
    },
    prevPage: function(){
        var prev = $('#materials-previous').text();
        if (prev){
            $('.loading_image').show();
            current_page = current_page - 1;
            InternalResources.queryAPI(InternalResources.getUrl() + '&page_number=' + prev);
        } else {
            // console.log("No next URL found!");
        }
    },
    setPosition: function(length) {
        var next = $('#materials-next').text();
        var prev = $('#materials-previous').text();
        $('#materials-next').text(current_page + 1);
        $('#materials-previous').text(current_page - 1);

        // Hide next button if there's a full page of results.
        if (length >= default_length) {
            $('#next-materials-button').show();
        } else {
            $('#next-materials-button').hide();
        }

        // Hide previous button if on first page
        if (current_page == 1) {
            $('#prev-materials-button').hide();
        } else {
            $('#prev-materials-button').show();
        }

    },
    associateResource: function(event){
        obj = $(event.target);

        // TODO: Replace this function. Example of required output in _internal_resource.erb
        // TODO: Fix the onclick name also - need to get 'material' from somewhere...
        var new_element = '<div id="material_internal_resource_' + obj.attr('id') + '">' +
            '<input type="hidden" name="event[material_ids][]" value="' + obj.attr('id') + '" />' +
            '<div class="alert alert-info">' +
            obj.data('title') +
            '<a href="#" class="delete-internal-resource pull-right" style="text-decoration: none;" ' +
            'onclick="delete_internal_resource(\'material_internal_resource_' + obj.attr('id') + '\')">' +
            '× </a></div></div>';
        $('#materials-list').append(new_element);


        obj.parent().parent().fadeOut();
    },
    queryAPI: function(url){
        //console.log(">>> queryAPI url: " + url);
        $('.loading_image').show();
        $.ajax({url: url,
            type: 'GET',
            dataType: 'json',
            headers: {'Accept': 'application/vnd.api+json'},
            contentType: 'application/json; charset=utf-8',
            success: function (result) {
                $('.loading_image').hide();
                InternalResources.setPosition(result.data.length);
                InternalResources.displayRecords(result);
            },
            error: function (error) {
                console.log(">>> Error querying for " + record_type + ": " + error);
            }
        });

    },
    displayRecords: function(json){
        //console.log("displayRecords json: " + json)
        $('#materials-results').empty();
        json.data.forEach(function(item, index) {
            var url = '/' + record_type + '/';
            // TODO: Come up with some decent icon choices here...
            if (record_type == 'materials') {
                var iconclass = "fa-book";
            } else {
                var iconclass = "fa-list-alt";
            }
            $('#materials-results').append('' +
                '<div id="' + item.id + '" class="col-md-12 col-sm-12 bounding-box" data-toggle=\"tooltip\" data-placement=\"top\" aria-hidden=\"true\" title=\"' + item.attributes['short-description'] + '\">' +
                '<h4>' +
                '<i class="fa ' +  iconclass + '"></i> ' +
                '<a href="' + url + item.id + '" target="_blank">' +
                '<span class="title">' +
                item.attributes.title +
                '</span>' +
                '</a>' +
                ' <i id="' + item.id + '" ' +
                'class="fa fa-plus-square-o associate-resource"/ ' +
                'title="click to associate ' + item.attributes.title + ' with this resource"' +
                'data-title="' + item.attributes.title + '" data-url="' + url + '"/>' +
                '</h4>' +
                '<span>' + truncateWithEllipses(item.attributes['description'], 600) + '</span>' +
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
    // console.log("Deleting resource: " + id);
    $('#' + id).remove();
}


document.addEventListener("turbolinks:load", function() {
    $(document).on('click', '.delete-internal-resource', function () {
        return false;
    });
    $('.loading_image').hide();
    // TODO: Find some way to set the next/prev button names depending on what sort of resource this is.
    $('#next-materials-button').click(InternalResources.nextPage);
    $('#prev-materials-button').click(InternalResources.prevPage);
    $('#materials-results').on('click','.associate-resource', InternalResources.associateResource);
    $('#materials_query').on({
        keyup: function() {
            if ($('#materials_query').val().length >= 3) {
                delay(function(){
                    InternalResources.search('materials');
                }, 1000 );
            }
        },
        keydown: function search(e) {
            if (e.keyCode === 13) {
                InternalResources.search('materials');
                e.preventDefault();
                return false;
            }
        }
    });
});
