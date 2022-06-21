var Autocompleters = {
    transformFunctions: {
        users: function (response) {
            return {
                suggestions: $.map(response, function (item) {
                    var name = item.username;
                    if (item.firstname) {
                        name = name + ' (' + item.firstname + ' ' + item.surname + ')';
                    }
                    return {value: name, data: item.id, item: item};
                })
            }
        }
    },

    create: function (element) {
        var existingValues = JSON.parse($(element).find('[data-role="autocompleter-existing"]').html()) || [];
        var listElement = $(element).find('[data-role="autocompleter-list"]');
        var inputElement = $(element).find('[data-role="autocompleter-input"]');
        var url = $(element).data("url");
        var prefix = $(element).data("prefix");
        var labelField = $(element).data("labelField") || "title";
        var idField = $(element).data("idField") || "id";
        var templateName = $(element).data("template") || "autocompleter/resource";
        var transformFunction;
        if ($(element).data("transformFunction")) {
            transformFunction = Autocompleters.transformFunctions[$(element).data("transformFunction")];
        } else {
            transformFunction = function (response) {
                return {
                    suggestions: $.map(response, function(item) {
                        return { value: item[labelField], data: item[idField], item: item };
                    })
                }
            };
        }

        // Render the existing associations on page load
        if (!listElement.children("li").length) {
            for (var i = 0; i < existingValues.length; i++) {
                listElement.append(HandlebarsTemplates[templateName](existingValues[i]));
            }
        }

        inputElement.autocomplete({
            serviceUrl: url,
            dataType: 'json',
            deferRequestBy: 300, // Wait 300ms before submitting to stop search being flooded
            paramName: 'q',
            transformResult: function(response) {
                return transformFunction(response);
            },
            onSelect: function (suggestion) {
                // Don't add duplicates
                if (!$("[data-id='" + suggestion.data + "']", listElement).length) {
                    var obj = { item: suggestion.item };
                    if (prefix) {
                        obj.prefix = prefix;
                    }

                    listElement.append(HandlebarsTemplates[templateName](obj));
                }

                $(this).val('').focus();
            },
            onSearchStart: function (query) {
                query.q = query.q + '*';
                inputElement.addClass('loading');
            },
            onSearchComplete: function () {
                inputElement.removeClass('loading');
            }
        });
    }
}