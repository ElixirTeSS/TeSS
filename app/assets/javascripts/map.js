class GoogleMap {
    constructor({ center, dom_element, zoom }) {
        this.markers = [];
        this.infowindow = new google.maps.InfoWindow({ content: "" });
        this.map = new google.maps.Map(dom_element, {
            center: new google.maps.LatLng(center.lat, center.lng),
            scrollwheel: true,
            zoom: zoom || 13,
            maxZoom: 17
        });
    }

    add_marker({ location, title, icon, description, link }) {
        var marker = new google.maps.Marker({
            map: this.map,
            position: { lat: parseFloat(location.lat), lng: parseFloat(location.lng)},
            title,
            icon: { url: icon, scaledSize: new google.maps.Size(35, 35) }
        });
        if (description) {
            google.maps.event.addListener(marker, 'click', () => {
                this.infowindow.setContent(description);
                this.infowindow.open(EventsMap.map, marker);
            });
        }
        if (link) {
            google.maps.event.addListener(
                marker, "dblclick", () => { window.open(link, '_self') }
            );
        }
        this.markers.push(marker);
    }

    delete_markers() {
        this.infowindow.close();
        this.markers.forEach((m) => m.setMap(null));
        this.markers = [];
    }

    fit_to_markers() {
        var marker_bounds = new google.maps.LatLngBounds();
        this.markers.forEach((m) => marker_bounds.extend(m.position));
        this.map.fitBounds(marker_bounds);
    }

    make_address_finder({ address_input, callback }) {
        var autocomplete = new google.maps.places.Autocomplete(address_input);
        autocomplete.bindTo('bounds', this.map);
        autocomplete.addListener('place_changed', () => {
            var place = autocomplete.getPlace();
            if (!place.geometry) {
                window.alert("Couldn't find that location on the map");
                return;
            }

            // If the place has a geometry, then present it on a map.
            if (place.geometry.viewport) {
                this.map.fitBounds(place.geometry.viewport);
            } else {
                this.map.setCenter(place.geometry.location);
                this.map.setZoom(17);  // Why 17? Because it looks good.
            }

            var address_info = {
                venue: place.name,
                city: null,
                country: null,
                postcode: null,
                lat: place.geometry.location.lat(),
                lng: place.geometry.location.lng()
            };
            var street_number = '';
            var street_short = '';
            var street_name = '';

            // Extract address fields
            for (var i = 0; i < place.address_components.length; i++) {
                var addressType = place.address_components[i].types[0];
                switch (addressType) {
                    case 'street_number':
                        street_number = place.address_components[i].short_name;
                        break;
                    case 'route':
                        street_name = place.address_components[i].long_name;
                        street_short = place.address_components[i].short_name;
                        break;
                    case 'locality':
                    case 'postal_town':
                        address_info.city = place.address_components[i].long_name;
                        break;
                    case 'administrative_area_level_2':
                        address_info.country = place.address_components[i].long_name;
                        break;
                    case 'country':
                        address_info.country = place.address_components[i].short_name;
                        break;
                    case 'postal_code':
                        address_info.postcode = place.address_components[i].short_name;
                        break;
                }
            }

            // Update venue with street address
            var street_address_short = street_number + ' ' + street_short;
            var street_address_long = street_number + ' ' + street_name;
            if (street_address_long.trim().length > 0 && address_info.venue !== street_address_long) {
                if (address_info.venue === street_address_short) {
                    address_info.venue = street_address_long;
                } else {
                    address_info.venue = place.name + ', ' + street_address_long;
                }
            }

            callback(address_info)
        })
    }
}


class OpenStreetMap {
    constructor({ center, dom_element, zoom }) {
        this.markers = [];
        this.info_windows = [];
        this.map = new ol.Map({
            target: dom_element,
            layers: [new ol.layer.Tile({ source: new ol.source.OSM() })],
            view: new ol.View({
                center: ol.proj.fromLonLat([center.lng, center.lat]),
                zoom: zoom || 13,
                maxZoom: 17
            })
        });
    }

    add_marker({ location, title, icon, description, link }) {
        if (icon) {
            var marker = $('<img width="35" height="35">');
            marker.prop("src", icon);
        }
        else {
            var marker = $(`
                <svg width="35" height="35" viewBox="0 0 40 60" xmlns="http://www.w3.org/2000/svg">
                    <path d="M20,0 C30,0 40,10 40,20 C40,35 20,60 20,60 C20,60 0,35 0,20 C0,10 10,0 20,0 Z" fill="#494a4b"/>
                    <circle cx="20" cy="20" r="8" fill="#f7db34"/>
                </svg>
            `);
        }

        marker.prop("src", icon);
        marker.prop("title", title);
        var point = ol.proj.fromLonLat([location.lng, location.lat])
        var overlay = new ol.Overlay({
            position: point,
            offset: [-17, -35],
            element: marker[0]
        });
        this.map.addOverlay(overlay);

        if (description) {
            var popup = $('<div class="ol-popup"><a class="ol-popup-closer" href="#"></a><div class="ol-popup-content"></div></div>').hide();
            popup.children(".ol-popup-content").html(description);

            var infowindow = new ol.Overlay({ element: popup[0], offset: [10, 10] });
            this.info_windows.push(infowindow);
            this.map.addOverlay(infowindow);
            infowindow.setPosition(point);
            marker.css("cursor", "pointer");
            marker.on('click', () => {
                popup.toggle();
                if (popup.is(':visible')) infowindow.panIntoView();
            });
            popup.on('click', () => {
                popup.hide();
                return false;
            });
        }
        if (link) {
            marker.css("cursor", "pointer");
            marker.on('dblclick', () => { window.open(link, '_self') })
        }
        this.markers.push(overlay)
    }

    delete_markers() {
        this.markers.forEach(m => this.map.removeOverlay(m));
        this.markers = [];
        this.info_windows.forEach(info => this.map.removeOverlay(info));
        this.info_windows = [];
    }

    fit_to_markers() {
        var fit_todo = true;
        this.map.on('loadend', () => {
            if (fit_todo) this.map.getView().fit(
                new ol.geom.MultiPoint(this.markers.map(m => m.getPosition())),
                { padding: [50, 50, 50, 50] }
            );
            fit_todo = false;
        });
    }

    make_address_finder({ address_input, callback }) {
        $(address_input).hide();
        var geocoder = new Geocoder('nominatim', {
            provider: 'osm',
            lang: $('html').prop('lang') || 'en',
            preventMarker: true,
            keepOpen: true,
        });
        this.map.addControl(geocoder);
        geocoder.on('addresschosen', (evt) => {
            var address_info = {
                venue: evt.address.details.name,
                city: evt.address.details.city,
                country: evt.address.details.country,
                postcode: evt.address.details.postcode,
                lat: evt.place.lat,
                lng: evt.place.lon
            };
            callback(address_info);
        });
        this.map.on('click', (evt) => {
            var coords = ol.proj.transform(evt.coordinate, 'EPSG:3857', 'EPSG:4326');
            var request_data = {
                lon: coords[0],
                lat: coords[1],
                format: 'json',
                limit: 1
            }
            $.get("https://nominatim.openstreetmap.org/reverse", request_data, response => {
                var address_info = {
                    venue: response.display_name,
                    city: response.address.city || response.address.town || response.address.village,
                    country: response.address.country_code.toUpperCase(),
                    postcode: response.address.postcode,
                    lat: request_data.lat,
                    lng: request_data.lon
                };
                callback(address_info);
            });
        })
    }
}


function get_map_class(provider) {
    return provider == 'google' ? GoogleMap : OpenStreetMap;
}


var EventMap = {
    init: function () {
        // Map on event show page
        var element = $('div.event-map');
        var loading_element = element.children("span");

        if (element.length && element.data('mapLatitude')) {
            var actualLocation = {
                lat: parseFloat(element.data('mapLatitude')),
                lng: parseFloat(element.data('mapLongitude'))
            };

            var suggestedLocation = {
                lat: parseFloat(element.data('mapSuggestedLatitude')),
                lng: parseFloat(element.data('mapSuggestedLongitude'))
            };

            var MapClass = get_map_class(element.data("map-provider"));
            var map = new MapClass({
                center: suggestedLocation.lat ? suggestedLocation : actualLocation,
                dom_element: element[0]
            });

            if (actualLocation.lat) {
                map.add_marker({
                    location: actualLocation,
                    title: element.data('mapMarkerTitle')
                });
            }

            if (suggestedLocation.lat) {
                map.add_marker({
                    location: suggestedLocation,
                    title: 'Suggested Location',
                    icon: element.data('mapSuggestedMarkerImage')
                });
            }
        }

        loading_element.hide();
    }
}

/* Set all filter links to include the anchor */
var addTabToFilters = function (tab) {
    if (tab) {
        $(function () {
            $('.active-filters a').attr('href', function (_, oldHref) {
                oldHref = oldHref.replace(/\#(.*)/g, "#" + tab);
                if (oldHref.indexOf('#') == -1)
                    oldHref += "#" + tab;
                return oldHref;
            })
            $('.nav-item a').attr('href', function (_, oldHref) {
                oldHref = oldHref.replace(/\#(.*)/g, "#" + tab);
                if (oldHref.indexOf('#') == -1)
                    oldHref += "#" + tab;
                return oldHref;
            });
        });
    }
};

var EventsMap = {
    map: null,
    init: function () {
        // Map on events index
        var element = $('[data-role="events-map"]');
        if (element.length) {
            EventsMap.map = null;

            var getTab = function () {
                var tab = window.location.hash;
                if (tab) {
                    return tab.substring(1) /* stip hash */
                } else {
                    return ''
                }
            };

            addTabToFilters(getTab());

            if (window.location.toString().endsWith('#map')) {
                // load map when entering site on events map page
                EventsMap.initializeMap(element);
            }
            $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
                /*Load map script only once when event tab is selected
                *
                * if (e.target.id == 'caltab'){
                    if (!loadedCalendarScript){
                      $.getScript('https://www.gstatic.com/charts/loader.js', function(){drawChart()});
                    }
                 }
                 */
                if (e.target.href.endsWith('#map')) {
                    if (!element.data('loadedMapScript')) {
                        EventsMap.initializeMap(element);
                    }
                    addTabToFilters('map');
                } else {
                    addTabToFilters('grid');
                }
            });
        }
    },

    initializeMap: function (element) {
        element.hide();
        $('#map-notice').hide();
        $('#map-loading-screen').fadeIn();

        var MapClass = get_map_class(element.data('provider'));
        EventsMap.map = new MapClass({
            center: { lat: 0, lng: 0 },
            dom_element: document.getElementById('map-canvas')
        });

        $.ajax({
            type: 'GET',
            url: element.data('url'),
            dataType: 'json',
        }).done(function (res) {
            EventsMap.plotEvents(res.data)
        }).fail(function (error) {
            console.log("Error: " + error);
        });

        element.data('loadedMapScript', true);
    },

    plotEvents: function (events) {
        var markers = {};
        var count = 0;

        events.forEach(function (event) {
            if (event.attributes.latitude !== null && event.attributes.longitude !== null) {
                count += 1;
                var event_display = HandlebarsTemplates['events/event_on_map']({ event: event.attributes });
                var key = Number(event.attributes.latitude) + ':' + Number(event.attributes.longitude);
                if (markers[key] != null) {
                    markers[key]['content'] = markers[key]['content'] + event_display
                    markers[key]['link'] = null;
                } else {
                    markers[key] = {
                        position: { lat: Number(event.attributes.latitude), lng: Number(event.attributes.longitude) },
                        content: event_display,
                        link: event.links.self,
                        title: '"' + event.attributes.title + '"' /* set to location? */
                    }
                }
            }
        });

        $.each(markers, function (k, event) {
            EventsMap.map.add_marker({
                location: event['position'],
                title: event['title'],
                description: event['content'],
                link: event.link
            })
        });

        $('#map-loading-screen').fadeOut();
        if (count > 0) {
            $('#map-canvas').fadeIn();
            $('#map-notice').show();
            $('#map-count').text('Displaying ' + count + ' events.');
            EventsMap.map.fit_to_markers();
        } else {
            $('#map-canvas').hide();
            $('#map-notice').hide();
            $('#map-count').text('No geolocation information provided for the selected events.');
        }
    }
}
