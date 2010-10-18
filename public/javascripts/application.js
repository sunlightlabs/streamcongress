$(document).ready(function() {

  if (!signed_in) {
    navigator.geolocation.getCurrentPosition(gotLocation);
  }

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

var loadFollowing = function() {
  var following_list = $('ul#following');
  var following_object = localStorage.get("following");

  _(following_object).each(function(leg_obj) {
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