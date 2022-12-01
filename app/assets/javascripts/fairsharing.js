var Fairsharing = {
    baseUrl: function () {
        return $('#fairsharing_query').data('fairsharingEndpoint');
    },
    titleElement: function() {
        return $('#' + $('#title_element').val())
    },
    queryParameter: function() {
        return $('#fairsharing_query').val();
    },
    typeParameter: function() {
        return $('input[name="bs_types[]"]:checked').val();
    },
    search: function(){
        Fairsharing.queryAPI(Fairsharing.queryParameter(), 1, Fairsharing.typeParameter());
    },
    nextPage: function(){
        var next = $('#fairsharing-next').text();
        if (next){
            Fairsharing.queryAPI(Fairsharing.queryParameter(), next, Fairsharing.typeParameter());
        } else {
            /* display nice "we're out of stuff" message here */
            // console.log("No next URL found!");
        }
    },
    prevPage: function(){
        var prev = $('#fairsharing-previous').text();
        if (prev){
            Fairsharing.queryAPI(Fairsharing.queryParameter(), prev, Fairsharing.typeParameter());
        } else {
            /* display nice "we're out of stuff" message here */
            // console.log("We're out of stuff!");
        }
    },
    queryAPI: function(query, page, type) {
        $('#fairsharing-loading-spinner').show();
        var data = { query: query };
        data['page'] = page || 1;
        data['type'] = type || 'any';
        $.ajax({
            url: Fairsharing.baseUrl(),
            data: data,
            type: 'GET',
            dataType: 'json',
            success: function (result) {
                Fairsharing.displayRecords(result);
            },
            error: function (error) {
                // console.log("Error querying FAIRsharing: " + JSON.stringify(error));
            },
            complete: function () {
                $('#fairsharing-loading-spinner').hide();
            }
        });
    },
    associateTool: function(event){
        var obj = $(this);
        ExternalResources.add(obj.data('title'), obj.data('url'));
        obj.parents('#fairsharing-results div').fadeOut();
    },
    displayRecords: function(json){
        $('#fairsharing-results').empty();
        var previous = json.prev_page;
        var next = json.next_page;
        if (previous) {
            $('#fairsharing-previous').text(previous);
            $('#prev-bs-button').show();
        } else {
            $('#prev-bs-button').hide();
        }
        if (next) {
            $('#fairsharing-next').text(next);
            $('#next-bs-button').show();
        } else {
            $('#next-bs-button').hide();
        }
        json.results.forEach(function (item) {
            var attributes = item.attributes;
            var metadata = attributes.metadata;
            var iconclass;
            if (attributes.fairsharing_registry === 'Policy') {
                iconclass = "fa fa-institution";
            } else if (attributes.fairsharing_registry === 'Database') {
                iconclass = "fa fa-database";
            } else {
                iconclass = "fa fa-list-alt";
            }

            $('#fairsharing-results').append(HandlebarsTemplates['external_resources/search_result']({
                name: metadata.name,
                url: attributes.url,
                description: metadata.description,
                truncatedDescription: truncateWithEllipses(metadata.description, 200),
                siteName: 'FAIRsharing',
                iconClass: iconclass
            }));
        });
        $('#next-bs-button').attr('data-next', json.next);
    },
    copyTitleAndSearch: function(){
        $('#fairsharing_query').val(Fairsharing.titleElement().val());
        Fairsharing.search();
    },
    init: function () {
        var delay = function () {
            var timer = 0;
            return function(callback, ms){
                clearTimeout (timer);
                timer = setTimeout(callback, ms);
            };
        }();

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
        $('#fairsharing-results').on('click', '.associate-tool', Fairsharing.associateTool);
        $('#external-resources').on('change', '.delete-external-resource-btn input.destroy-attribute', ExternalResources.delete);
        Fairsharing.titleElement().blur(Fairsharing.copyTitleAndSearch);
    }
};

