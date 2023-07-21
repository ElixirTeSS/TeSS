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
            Autocompleters.initGroup(this);
        });
    },

    initGroup: function (element, opts) {
        var existingValues = JSON.parse($(element).find('[data-role="autocompleter-existing"]').html()) || [];
        var listElement = $(element).find('[data-role="autocompleter-list"]');
        var inputElement = $(element).find('[data-role="autocompleter-input"]');
        var defaults = {
            url: $(element).data("url"),
            prefix: $(element).data("prefix"),
            labelField: $(element).data("labelField") || "title",
            idField: $(element).data("idField") || "id",
            singleton: $(element).data("singleton") || false,
            groupBy: $(element).data("groupBy") || false,
            templateName: $(element).data("template"),
            transformFunction: Autocompleters.transformFunctions[$(element).data("transformFunction") || "default"]
        }
        opts = Object.assign({}, defaults, opts);

        opts.templateName = opts.templateName || (opts.singleton ? "autocompleter/singleton_resource" :
            "autocompleter/resource");

        // Render the existing associations on page load
        if (!listElement.children("li").length) {
            for (var i = 0; i < existingValues.length; i++) {
                listElement.append(HandlebarsTemplates[opts.templateName](existingValues[i]));
            }

            if (opts.singleton && existingValues.length) {
                inputElement.hide();
            }
        }

        inputElement.autocomplete({
            serviceUrl: opts.url,
            dataType: "json",
            deferRequestBy: 300, // Wait 300ms before submitting to stop search being flooded
            paramName: "q",
            groupBy: opts.groupBy,
            formatResult: Autocompleters.formatResultWithHint,
            transformResult: function(response) {
                return opts.transformFunction(response, opts);
            },
            onSelect: function (suggestion) {
                // Don't add duplicates
                var id = suggestion.data.id;
                if (!$("[data-id='" + id + "']", listElement).length) {
                    var obj = { item: suggestion.data.item };
                    if (opts.prefix) {
                        obj.prefix = opts.prefix;
                    }

                    listElement.append(HandlebarsTemplates[opts.templateName](obj));
                    if (opts.singleton) {
                        inputElement.hide();
                    }
                }

                $(this).val('').focus();
                const event = new CustomEvent('autocompleters:added', {  bubbles: true, detail: { object: obj } });
                listElement[0].dispatchEvent(event);
            },
            onSearchStart: function (query) {
                inputElement.addClass("loading");
            },
            onSearchComplete: function () {
                inputElement.removeClass("loading");
            }
        });
    }
}