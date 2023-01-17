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
        $('#fairsharing-results').empty();
        Fairsharing.queryAPI(Fairsharing.queryParameter(), 1, Fairsharing.typeParameter());
    },
    nextPage: function(){
        var next = $(this).data('page');
        if (next) {
            Fairsharing.queryAPI(Fairsharing.queryParameter(), next, Fairsharing.typeParameter());
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
                console.log("Error querying FAIRsharing: " + JSON.stringify(error));
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

        if (json.next_page) {
            $('#next-bs-button').data('page', json.next_page).show();
        } else {
            $('#next-bs-button').hide();
        }
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
        $('#fairsharing-results').on('click', '.associate-resource', Fairsharing.associateTool);
        $('#external-resources').on('change', '.delete-external-resource-btn input.destroy-attribute', ExternalResources.delete);
        Fairsharing.titleElement().blur(Fairsharing.copyTitleAndSearch);
    }
};
