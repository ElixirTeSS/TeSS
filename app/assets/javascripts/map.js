var Map = {
    init: function () {
        // Map on event show page
        var element = $('div.google-map');

        if (element.length && element.data('mapLatitude')) {
            var actualLocation = {
                lat: parseFloat(element.data('mapLatitude')),
                lng: parseFloat(element.data('mapLongitude'))
            };

            var suggestedLocation = {
                lat: parseFloat(element.data('mapSuggestedLatitude')),
                lng: parseFloat(element.data('mapSuggestedLongitude'))
            };

            // Create a map object and specify the DOM element for display.
            var map = new google.maps.Map(element[0], {
                center: suggestedLocation.lat ? suggestedLocation : actualLocation,
                scrollwheel: true,
                zoom: 13,
                maxZoom: 15,
            });

            if (actualLocation.lat) {
                new google.maps.Marker({
                    map: map,
                    position: actualLocation,
                    title: element.data('mapMarkerTitle')
                });
            }

            if (suggestedLocation.lat) {
                new google.maps.Marker({
                    map: map,
                    position: suggestedLocation,
                    title: 'Suggested Location',
                    icon: element.data('mapSuggestedMarkerImage')
                });
            }
        }
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

        $.ajax({
            type: 'GET',
            url: element.data('url'),
            dataType: 'json',
        }).done(function (res) {
            EventsMap.plotEvents(res.data)
        }).fail(function (error) {
            console.log("Error: " + error);
        });

        var mapOptions = {
            maxZoom: 15,
            center: new google.maps.LatLng(0, 0)
        };

        EventsMap.map = new google.maps.Map(document.getElementById('map-canvas'), mapOptions);

        element.data('loadedMapScript', true);
    },

    plotEvents: function (events) {
        var infowindow = new google.maps.InfoWindow({content: content});
        var markers = {};
        var count = 0;

        events.forEach(function(event) {
            if (event.attributes.latitude !== null && event.attributes.longitude !== null) {
                count += 1;
                var event_display = HandlebarsTemplates['events/event_on_map']({event: event.attributes});
                var key = Number(event.attributes.latitude) + ':' + Number(event.attributes.longitude);
                if (markers[key] != null){
                    markers[key]['content'] = markers[key]['content'] + event_display
                } else {
                    markers[key] = {
                        position: {lat: Number(event.attributes.latitude), lng: Number(event.attributes.longitude)},
                        content: event_display,
                        title: '"' + event.attributes.title + '"' /* set to location? */
                    }
                }
            }
        });

        var bounds = new google.maps.LatLngBounds();
        $.each(markers, function(k, event){
            var marker = new google.maps.Marker({
                position: event['position'],
                map: EventsMap.map,
                title: event['title']
            });
            google.maps.event.addListener(marker, 'click', function () {
                infowindow.setContent(event['content']);
                infowindow.open(EventsMap.map, marker);
            });
            bounds.extend(marker.position);
        });

        $('#map-loading-screen').fadeOut();
        if (count > 0) {
            $('#map-canvas').fadeIn();
            $('#map-notice').show();
            $('#map-count').text('Displaying ' + count + ' events.');
            EventsMap.map.fitBounds(bounds);
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
