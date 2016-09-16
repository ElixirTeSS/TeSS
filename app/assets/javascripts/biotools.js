var Biotools = {
    titleElement: function() {
        return $('#' + $('#title_element').val())
    },
    sortParameter: function() {
        return 'sort=score';
    },
    queryParameter: function() {
        return 'q=' + encodeURIComponent($('#tool_query').val());
    },
    apiBase: function(){
        return 'https://dev.bio.tools/api/tool';
    },
    search: function(){
        $('#biotools-results').empty();
        Biotools.queryAPI(Biotools.apiBase() + '?' + Biotools.queryParameter() + '&' + Biotools.sortParameter());
    },
    nextPage: function(){
        var next_page = $(event.target).attr('data-next');
        if (next_page){
            Biotools.queryAPI(Biotools.apiBase() + next_page + '&' + Biotools.queryParameter() + '&' + Biotools.sortParameter());
        } else {
            /* display nice 'were out of tools  message here */
        }
    },
    queryAPI: function(api_url){
        $.get(api_url, function (json) {
            Biotools.displayTools(json);
        });
    }, 
    associateTool: function(event){
        obj = $(event.target);
        Materials.externalResources.add(obj.data('title'), obj.data('url'));
        obj.parent().parent().fadeOut();
    },
    displayTools: function(json){
        var items = json.list;
        $.each(items, function (index, item) {
            var url = 'https://dev.bio.tools/tool/' + item.id;
            $('#biotools-results').append('' +
                '<div id="' + item.id + '" class="col-md-12 col-sm-12" data-toggle=\"tooltip\" data-placement=\"top\" aria-hidden=\"true\" title=\"' + item.description + '\">' +
                '<h4>' +
                '<i class="fa fa-wrench"></i> ' +
                '<a href="' + url + '">' +
                '<span class="title">' +
                item.name +
                '</span>' +
                '</a>' +
                ' <i id="' + item.id + '" ' +
                'class="fa fa-plus-square-o associate-tool"/ ' +
                'title="click to associate ' + item.name + ' with this resource"' +
                'data-title="' + item.name + '" data-url="' + url + '"/>' +
                '</h4>' +
                '<span>' + item.description + '</span>' +
                '</div>');
        });
        $('#next-tools-button').attr('data-next', json.next);
    },
    copyTitleAndSearch: function(){
        $('#tool_query').val(Biotools.titleElement().val());
        Biotools.search();
    }
};

$(document).ready(function () {
    $('#external-resources').on('click', '#add-external-resource-btn', Materials.externalResources.add);
    $('#next-tools-button').click(Biotools.nextPage);
    $('#tool_query').keyup(Biotools.search);
    $('#search_tools').click(Biotools.search);
    $('#biotools-results').on('click','.associate-tool', Biotools.associateTool);$('#external-resources').on('change', '.delete-external-resource-btn input.destroy-attribute', Materials.externalResources.delete);
    Biotools.titleElement().keyup(Biotools.copyTitleAndSearch);
    Biotools.copyTitleAndSearch();
    Biotools.queryAPI(Biotools.apiBase() + '?' + Biotools.queryParameter() + '&' + Biotools.sortParameter());

});


