var Ror = {
    getName: function (item) {
        var names = item.names || [];
        for (var i = 0; i < names.length; i++) {
            if (names[i].types && names[i].types.indexOf('ror_display') !== -1) {
                return names[i].value;
            }
        }
        return names.length ? names[0].value : item.id;
    },

    getCountry: function (item) {
        var location = (item.locations || [])[0];
        return location && location.geonames_details ? location.geonames_details.country_name : null;
    },

    transformResult: function (response) {
        return {
            suggestions: $.map(response.items || [], function (item) {
                var country = Ror.getCountry(item);
                return {
                    value: Ror.getName(item),
                    data: {
                        ror: item.id,
                        hint: country ? country : item.id
                    }
                };
            })
        };
    },

    init: function () {
        $('[data-role="ror-autocomplete"]').each(function () {
            $(this).autocomplete({
                serviceUrl: $(this).data('autocompleteUrl'),
                dataType: 'json',
                minChars: 3,
                deferRequestBy: 300,
                triggerSelectOnValidInput: false,
                transformResult: Ror.transformResult,
                formatResult: Autocompleters.formatResultWithHint,
                onSelect: function (suggestion) {
                    $(this).val(suggestion.data.ror);
                }
            });
        });
    }
};
