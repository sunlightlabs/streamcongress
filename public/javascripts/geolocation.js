var gotLocation = function(loc) {
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

    }
  });
}

