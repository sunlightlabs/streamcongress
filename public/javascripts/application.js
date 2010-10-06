$(document).ready(function() {

  if (!signed_in) {
    navigator.geolocation.getCurrentPosition(gotLocation);
  }

  function gotLocation(loc) {
    var geo_url = 'http://nominatim.openstreetmap.org/reverse?format=json&lat=' + loc.coords.latitude + '&lon='+ loc.coords.longitude + '&json_callback=?'
    $.getJSON(geo_url, function(data) {
      var address = data.address;
      $('span#following_tip').text("Current city: " + address.city);
    });

    var sunlight_url = 'http://services.sunlightlabs.com/api/legislators.allForLatLong.json?jsonp=?&apikey=eb9a0cebe6e940cf827ca2592b11fc3f&latitude=' + loc.coords.latitude + '&longitude=' + loc.coords.longitude;
    $.ajax({
      url: sunlight_url,
      dataType: 'json',
      jsonp: 'jsonp',
      success: function(data) {

        var following_list = $('ul#following');

        _(data.response.legislators).each(function(leg_obj) {
          var legislator = leg_obj.legislator;
          var name = legislator.title + ". ";
          if (legislator.nickname == "") {
            name = name + legislator.firstname;
          } else {
            name = name + legislator.nickname;
          }
          name = name + " " + legislator.lastname + " (" + legislator.party + "-" + legislator.state + ")";
          following_list.append('<li><a href="#">' + name + '</a><a class="delete" href="#">Delete</a><div class="clear"></div></li>');
        });
      }
    });
  }

  function debug(str){ $("#debug").append("<p>" + str + "</p>"); };

  ws = new WebSocket("ws://localhost:8080");
  ws.onmessage = function(activity) {
    $("#stream").prepend("<p class='activity'>" + activity.data + "</p>");
  };
  ws.onclose = function() {
    debug("Socket closed!");
  };
  ws.onopen = function() {
    debug("Socket connected!");
  };
});
