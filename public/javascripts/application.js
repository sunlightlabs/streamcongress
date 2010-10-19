$(document).ready(function() {

  if (!signed_in && _(JSON.parse(localStorage["following"])).isEmpty()) {

    var following = [];
    _(defaultFollows).each(function(pair) {
      following.push({"name": pair[0], "id": pair[1] })
    });
    localStorage["following"] = JSON.stringify(following);

    navigator.geolocation.getCurrentPosition(gotLocation);

  } else {
    $('span#following_tip').text("Loaded your saved follow list...");
    $('article#geolocationPrompt').hide();
    loadFollowing();
  }

  ws = new WebSocket("ws://localhost:8080");
  ws.onmessage = function(activity) {
    $("#stream").prepend("<p class='activity'>" + activity.data + "</p>");
  };
  ws.onclose = function() {
    //debug("Socket closed!");
  };
  ws.onopen = function() {
    //debug("Socket connected!");
  };
});

var loadFollowing = function() {

  var following_ul = $('ul#following');

  _(JSON.parse(localStorage["following"])).each(function(publisher) {
    following_ul.append('<li><a href="#">' + publisher["name"] + '</a><a class="delete" href="#">Delete</a><div class="clear"></div></li>');
  });

}