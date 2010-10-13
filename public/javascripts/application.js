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
