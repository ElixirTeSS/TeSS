class GoogleMap {
    constructor({ center, dom_element }) {
        this.marker_bounds = new google.maps.LatLngBounds();
        this.infowindow = new google.maps.InfoWindow({content: content});
        this.map = new google.maps.Map(dom_element, {
            center,
            scrollwheel: true,
            zoom: 13,
            maxZoom: 17
        });
    }

    add_marker({ location, title, icon, description }) {
        var marker = new google.maps.Marker({
            map: this.map,
            position: location,
            title,
            icon
        });
        if (description) {
            google.maps.event.addListener(marker, 'click', function () {
                infowindow.setContent(description);
                infowindow.open(EventsMap.map, marker);
            });
        }
        this.marker_bounds.extend(marker.position);
        return marker;
    }

    fit_to_markers() {
        this.map.fitBounds(this.marker_bounds);
    }
}


class OpenStreetMap {
    constructor({ center, dom_element }) {
        this.marker_points = [];
        this.map = new ol.Map({
            target: dom_element,
            layers: [new ol.layer.Tile({ source: new ol.source.OSM() })],
            view: new ol.View({
                center: ol.proj.fromLonLat([center.lng, center.lat]),
                zoom: 13,
                maxZoom: 17
            })
        });
    }

    add_marker({ location, title, icon, description, link }) {
        icon = icon || 'https://pan-training.eu/events/marker.png';
        var marker = $('<img width="50" height="50" style="cursor: pointer;">');
        marker.prop("src", icon);
        marker.prop("title", title);
        var point = ol.proj.fromLonLat([location.lng, location.lat])
        this.map.addOverlay(new ol.Overlay({
            position: point,
            offset: [-25, -50],
            element: marker[0]
        }));
        
        if (description) {
            var popup = $('<div class="ol-popup"><a class="ol-popup-closer" href="#"></a><div class="ol-popup-content"></div></div>').hide();
            popup.children(".ol-popup-content").html(description);
            
            var infowindow = new ol.Overlay({element: popup[0], offset: [10, 10]});
            this.map.addOverlay(infowindow);
            infowindow.setPosition(point);
            marker.on('click', () => {
                popup.toggle();
                if(popup.is(':visible')) infowindow.panIntoView();
            });   
            popup.on('click', () => {
                popup.hide();
                return false;
            });
        }
        if (link) {
            marker.on('dblclick', () => {window.open(link, '_self')})
        }
        this.marker_points.push(point);
    }

    fit_to_markers() {
        var fit_todo = true;
        this.map.on('loadend', () => {
            if(fit_todo) this.map.getView().fit(new ol.geom.MultiPoint(this.marker_points), { padding: [50, 50, 50, 50] });
            fit_todo = false;
        });
    }
}


var EventMap = {
    init: function () {
        // Map on event show page
        var element = $('div.google-map');
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

            var MapClass = element.data("map-provider") == 'google' ? GoogleMap : OpenStreetMap;
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

            if(window.location.toString().endsWith('#map')){
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

        var MapClass = element.data('provider') == 'google' ? GoogleMap : OpenStreetMap;
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

/*
<script>
var map;
var events = [];
var loadedMapScript = false;
var events_shown = 0;

/* center on (0, 0). Map center and zoom will reconfigure later (fitbounds method)*/
/*
var mapOptions = {
    zoom: 10,
    center: new google.maps.LatLng(0, 0)
};


function prep() {
<% unless events.blank? %>
<% events.each do |event|  %>
    var event_display = HandlebarsTemplates['events/event_on_map']({event: event.attributes})
    events.push([
    <%=event.latitude%>,
    <%=event.longitude%>,
        event_display,
        "<%=event.title%>"
]);
<% end %>
    <% end %>
    //console.log(events.length + " initial events.");
}

function initialize() {
    events_shown = 0;
    prep();
    var map = new google.maps.Map(document.getElementById('map-canvas'), mapOptions);
    setEvents(map, events);
    $('#map-count').text(events_shown);
    loadedMapScript = true;
}

function setEvents(map, events) {
    var bounds = new google.maps.LatLngBounds();
    var pins = {};
    for (var i = 0; i < events.length; i++) {
        // Check lat/lon are defined to avoid "Too much recursion" error
        if (typeof events[i][0] === 'number' && typeof events[i][1] === 'number') {
            var key = events[i][0] + ':' + events[i][1];
            //console.log("KEY: " + key);
            if (!(key in pins)) {
                pins[key] = [];
            }
            pins[key].push(events[i]);
            events_shown = events_shown + 1;
        }
    }
    for (var key in pins) {
        // console.log("KEY: " + key);
        var content = "";
        var count = pins[key].length;
        var title = count + ' event(s) at ' + pins[key][0][0] + ", " + pins[key][0][1];
        var position = {lat: pins[key][0][0], lng: pins[key][0][1]};
        pins[key].forEach(function(event) {
            // console.log("EVENT: " + event[2]);
            content += event[2] + "<br/>"
        });
        var infowindow = new google.maps.InfoWindow({content: content});
        var new_marker = createMarker(map, position, infowindow, title, content);
        bounds.extend(new_marker.position);
    }
    map.fitBounds(bounds);
}


function createMarker(map, position, infowindow, title, content) {
    var marker = new google.maps.Marker({
        position: position,
        map: map,
        title: title
    });
    google.maps.event.addListener(marker, 'click', function () {
        infowindow.setContent(content);
        infowindow.open(map, marker);
    });
    return marker;
}

function showAllEvents() {
    events_shown = 0;
    var new_events = [];
    $.ajax({
        type: 'GET',
        url: '<%= events_url(params.merge(format: :json_api)).html_safe -%>',
        dataType: 'json',
    }).done(function (res) {
        res.data.forEach(function(event) {
            if (event.attributes.latitude !== null && event.attributes.longitude !== null) {
                var event_display = HandlebarsTemplates['events/event_on_map']({event: event.attributes})
                new_events.push([
                    Number(event.attributes.latitude),
                    Number(event.attributes.longitude),
                    event_display,
                    '"' + event.attributes.title + '"'
                ]);
            }
        });
        //console.log(new_events.length + " new events.");
        var map = new google.maps.Map(document.getElementById('map-canvas'), mapOptions);
        setEvents(map, new_events);
        $('#map-count').text(events_shown);
        loadedMapScript = true;
    }).fail(function (error) {
        // console.log("Error: " + error);
    });
}

function clearMap() {
    events = [];
    events_shown = 0;
    var map = new google.maps.Map(document.getElementById('map-canvas'), mapOptions);
    var clock = new google.maps.LatLng(53.1411505,0.345498);
    map.panTo(clock);
    $('#map-count').text(events_shown);
}

function showCurrentPageEvents() {
    events = [];
    initialize();
}

function stringForNull(value) {
    return (value == null) ? "" : value;
}

</script>

*/
