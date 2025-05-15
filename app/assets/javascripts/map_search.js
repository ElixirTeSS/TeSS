var MapSearch = {
    map: null,
    marker: null,
    infowindow: null,
    init: function () {
        var element = $('#event-map-form');
        if (element.length) {
            var loading_element = element.children('span');
            var showMarker = element.data('mapShowMarker');
            var provider = element.data('mapProvider');
            var marker_icon = provider === 'google' ? 'https://maps.gstatic.com/mapfiles/place_api/icons/geocode-71.png' : undefined;
            MapClass = get_map_class(provider);
            MapSearch.map = new MapClass({
                center: {
                    lat: parseFloat(element.data('mapLatitude')),
                    lng: parseFloat(element.data('mapLongitude'))
                }, // Center on existing event, or default location
                dom_element: element[0],
                zoom: parseInt(element.data('mapZoom'))
            })

            var input = document.getElementById('map-search');
            MapSearch.map.make_address_finder({
                address_input: input,
                add_marker: showMarker,
                callback: ({venue, lat, lng, city, country, postcode}) => {
                    MapSearch.hideMarker();

                    $('#event_venue').val(venue);
                    $('#event_latitude').val(lat);
                    $('#event_longitude').val(lng);

                    if(city != null) $('#event_city').val(city);
                    $('#event_country').children("option").each((i, c) => {
                        if($(c).text().indexOf(country) !== -1) country = $(c).val()
                    });
                    if(country != null) $('#event_country').val(country);
                    if(postcode != null) $('#event_postcode').val(postcode);
                    
                    MapSearch.placeMarker(marker_icon);
                }
            });

            if (showMarker) {
                MapSearch.placeMarker();
            }
            loading_element.hide(marker_icon);
        }
    },

    placeMarker: function (icon) {
        var venue = $('#event_venue').val();
        var city_country = [
            $('#event_city').val(), 
            $('#event_country').val()
        ].filter(Boolean).join(', ');
        MapSearch.map.add_marker({
            location: {
                lat: $('#event_latitude').val(),
                lng: $('#event_longitude').val()
            },
            icon: icon,
            description: '<div><strong>' + venue + '</strong><br>' + city_country
        })
    },

    hideMarker: function () {
        MapSearch.map.delete_markers();
    }
};
