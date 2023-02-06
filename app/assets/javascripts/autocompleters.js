var Autocompleters = {
    formatResultWithHint: function (suggestion, currentValue) {
        var result = $.Autocomplete.defaults.formatResult(suggestion, currentValue);

        if (suggestion.data && suggestion.data.hint) {
            result += '<span class="autocomplete-hint">' + suggestion.data.hint + '</span>';
        }

        return result;
    },
    transformFunctions: {
        default: function (response, config) {
            return {
                suggestions: $.map(response, function(item) {
                    return { value: item[config.labelField], data: { id: item[config.idField], item: item } };
                })
            };
        },
        events: function (response, config) {
            var today = new Date();
            return {
                suggestions: $.map(response, function(item) {
                    var group;
                    if (item.end && new Date(item.end) < today) {
                        group = 'Past';
                    } else {
                        group = 'Upcoming';
                    }
                    var hint = null;
                    if (item.start) {
                        hint = item.start.substr(0,10);
                    }
                    return { value: item[config.labelField], data: { id: item[config.idField], group: group, item: item, hint: hint } };
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
                    return { value: name, data: { id: item[config.idField], item: item } };
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
            var groupBy = $(element).data("groupBy") || false;
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
                groupBy: groupBy,
                formatResult: Autocompleters.formatResultWithHint,
                transformResult: function(response) {
                    return transformFunction(response, { labelField: labelField, idField: idField });
                },
                onSelect: function (suggestion) {
                    // Don't add duplicates
                    var id = suggestion.data.id;
                    if (!$("[data-id='" + id + "']", listElement).length) {
                        var obj = { item: suggestion.data.item };
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
                    inputElement.addClass("loading");
                },
                onSearchComplete: function () {
                    inputElement.removeClass("loading");
                }
            });
        });
    }
}