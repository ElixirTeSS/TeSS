var MapSearch = {
    map: null,
    marker: null,
    infowindow: null,
    init: function () {
        var element = $('#google-map-form');
        if (element.length) {
            var showMarker = element.data('mapShowMarker');
            MapSearch.map = new google.maps.Map(element[0], {
                center: {
                    lat: parseFloat(element.data('mapLatitude')),
                    lng: parseFloat(element.data('mapLongitude'))
                }, // Center on existing event, or default location
                zoom: parseInt(element.data('mapZoom'))
            });
            var input = document.getElementById('map-search');

            var autocomplete = new google.maps.places.Autocomplete(input);
            autocomplete.bindTo('bounds', MapSearch.map);

            MapSearch.infowindow = new google.maps.InfoWindow();
            MapSearch.marker = new google.maps.Marker({
                map: MapSearch.map,
                anchorPoint: new google.maps.Point(0, -29)
            });

            autocomplete.addListener('place_changed', function () {
                MapSearch.hideMarker();

                var place = autocomplete.getPlace();
                if (!place.geometry) {
                    window.alert("Couldn't find that location on the map");
                    return;
                }

                // If the place has a geometry, then present it on a map.
                if (place.geometry.viewport) {
                    MapSearch.map.fitBounds(place.geometry.viewport);
                } else {
                    MapSearch.map.setCenter(place.geometry.location);
                    MapSearch.map.setZoom(17);  // Why 17? Because it looks good.
                }

                // Populate address fields
                var venue = place.name;
                var street_number = '';
                var street_name = '';
                var street_short = '';

                //var message = 'place.name: ' + place.name;
                //var newline = '\r\n';

                for (var i = 0; i < place.address_components.length; i++) {
                    var addressType = place.address_components[i].types[0];
                    //message = message + newline + addressType + ': ' + place.address_components[i].long_name + ' (' +
                    //    place.address_components[i].short_name + ')';
                    switch (addressType) {
                        case 'street_number':
                            street_number = place.address_components[i].short_name;
                            break;
                        case 'route':
                            street_name = place.address_components[i].long_name;
                            street_short = place.address_components[i].short_name;
                            break;
                        case 'locality':
                            $('#event_city').val(place.address_components[i].long_name);
                            break;
                        case 'administrative_area_level_2':
                            $('#event_county').val(place.address_components[i].long_name);
                            break;
                        case 'country':
                            $('#event_country').val(place.address_components[i].short_name);
                            break;
                        case 'postal_code':
                            $('#event_postcode').val(place.address_components[i].short_name);
                            break;
                    }
                }

                var street_address_short = street_number + ' ' + street_short;
                var street_address_long = street_number + ' ' + street_name;
                if (street_address_long.trim().length > 0 && venue != street_address_long) {
                    if (venue == street_address_short) {
                        venue = street_address_long;
                    } else {
                        venue = place.name + ', ' + street_address_long;
                    }
                }

                //window.alert(message);

                $('#event_venue').val(venue);
                $('#event_latitude').val(place.geometry.location.lat());
                $('#event_longitude').val(place.geometry.location.lng());

                MapSearch.placeMarker();
            });

            if (showMarker) {
                MapSearch.placeMarker();
            }
        }
    },

    placeMarker: function () {
        var venue = $('#event_venue').val();
        var city = $('#event_city').val();
        var country = $('#event_country').val();
        var postcode = $('#event_postcode').val();
        var lat = $('#event_latitude').val();
        var lon = $('#event_longitude').val();

        MapSearch.marker.setIcon(/** @type {google.maps.Icon} */({
            url: 'https://maps.gstatic.com/mapfiles/place_api/icons/geocode-71.png',
            size: new google.maps.Size(71, 71),
            origin: new google.maps.Point(0, 0),
            anchor: new google.maps.Point(17, 34),
            scaledSize: new google.maps.Size(35, 35)
        }));
        MapSearch.marker.setPosition(new google.maps.LatLng(lat, lon));
        MapSearch.marker.setVisible(true);

        MapSearch.infowindow.setContent('<div><strong>' + venue + '</strong><br>' + city + ', ' + country);
        MapSearch.infowindow.open(MapSearch.map, MapSearch.marker);
    },

    hideMarker: function () {
        MapSearch.infowindow.close();
        MapSearch.marker.setVisible(false);
    }
};
