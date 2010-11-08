var gotLocation = function(loc) {

  var memberLookup = {};
  _(allMembers).each(function(tuple) {
    memberLookup[tuple[0]] = { "name" : tuple[1], "id" : tuple[2] };
  });

  var geo_url = 'http://nominatim.openstreetmap.org/reverse?format=json&lat=' + loc.coords.latitude + '&lon='+ loc.coords.longitude + '&json_callback=?'
  $.getJSON(geo_url, function(data) {
    var address = data.address;
    $('span#following_tip').text("Current city: " + address.city);
    store.set("currentCity", address.city);
  });

  var sunlight_url = 'http://services.sunlightlabs.com/api/legislators.allForLatLong.json?jsonp=?&apikey=' + sunlightKey + '&latitude=' + loc.coords.latitude + '&longitude=' + loc.coords.longitude;
  $.ajax({
    url: sunlight_url,
    dataType: 'json',
    jsonp: 'jsonp',
    success: function(data) {
      var following = store.get("following");
      // append legislators to following
      _(data.response.legislators).each(function(leg_obj) {
        var legislator = leg_obj.legislator;
        following.push(memberLookup[legislator.bioguide_id]);
      });
      store.set("following", following);
      loadStored();
      $('article#geolocationPrompt').hide();
    }
  });

}

