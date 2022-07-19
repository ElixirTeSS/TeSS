var Autocompleters = {
    transformFunctions: {
        default: function (response, config) {
            return {
                suggestions: $.map(response, function(item) {
                    return { value: item[config.labelField], data: item[config.idField], item: item };
                })
            };
        },
        users: function (response, config) {
            return {
                suggestions: $.map(response, function (item) {
                    var name = item.username;
                    if (item.firstname) {
                        name = name + " (" + item.firstname + " " + item.surname + ")";
                    }
                    item.name = name;
                    return { value: name, data: item[config.idField], item: item };
                })
            };
        }
    },

    init: function () {
        $("[data-role='autocompleter-group']").each(function () {
            var element = this;
            var existingValues = JSON.parse($(element).find('[data-role="autocompleter-existing"]').html()) || [];
            var listElement = $(element).find('[data-role="autocompleter-list"]');
            var inputElement = $(element).find('[data-role="autocompleter-input"]');
            var url = $(element).data("url");
            var prefix = $(element).data("prefix");
            var labelField = $(element).data("labelField") || "title";
            var idField = $(element).data("idField") || "id";
            var singleton = $(element).data("singleton") || false;
            var templateName = $(element).data("template") ||
                (singleton ? "autocompleter/singleton_resource" : "autocompleter/resource");
            var transformFunction = Autocompleters.transformFunctions[$(element).data("transformFunction") || "default"];

            // Render the existing associations on page load
            if (!listElement.children("li").length) {
                for (var i = 0; i < existingValues.length; i++) {
                    listElement.append(HandlebarsTemplates[templateName](existingValues[i]));
                }

                if (singleton && existingValues.length) {
                    inputElement.hide();
                }
            }

            inputElement.autocomplete({
                serviceUrl: url,
                dataType: "json",
                deferRequestBy: 300, // Wait 300ms before submitting to stop search being flooded
                paramName: "q",
                transformResult: function(response) {
                    return transformFunction(response, { labelField: labelField, idField: idField });
                },
                onSelect: function (suggestion) {
                    // Don't add duplicates
                    if (!$("[data-id='" + suggestion.data + "']", listElement).length) {
                        var obj = { item: suggestion.item };
                        if (prefix) {
                            obj.prefix = prefix;
                        }

                        listElement.append(HandlebarsTemplates[templateName](obj));
                        if (singleton) {
                            inputElement.hide();
                        }
                    }

                    $(this).val('').focus();
                },
                onSearchStart: function (query) {
                    query.q = query.q + "*";
                    inputElement.addClass("loading");
                },
                onSearchComplete: function () {
                    inputElement.removeClass("loading");
                }
            });
        });
    }
}