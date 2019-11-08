
var loadedMapScript = false;
var map;
var count;


function plotEvents(events){
    var infowindow = new google.maps.InfoWindow({content: content});
    var markers = {};
    count = 0;

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
            map: map,
            title: event['title']
        });
        google.maps.event.addListener(marker, 'click', function () {
            infowindow.setContent(event['content']);
            infowindow.open(map, marker);
        });
        bounds.extend(marker.position);
    });

    $('#map-loading-screen').fadeOut();
    if (count > 0) {
        $('#map-canvas').fadeIn();
        $('#map-notice').show();
        $('#map-count').text('Displaying ' + count + ' events.');
        map.fitBounds(bounds);
    } else {
        $('#map-canvas').hide();
        $('#map-notice').hide();
        $('#map-count').text('No geolocation information provided for the selected events.');
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
        console.log("KEY: " + key);
        var content = "";
        var count = pins[key].length;
        var title = count + ' event(s) at ' + pins[key][0][0] + ", " + pins[key][0][1];
        var position = {lat: pins[key][0][0], lng: pins[key][0][1]};
        pins[key].forEach(function(event) {
            console.log("EVENT: " + event[2]);
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
        console.log("Error: " + error);
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
