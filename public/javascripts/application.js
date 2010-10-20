$(document).ready(function() {

  $("#activityTemplate").template("activity");

  if (!signed_in && _(store.get("following")).isEmpty()) {

    var following = [];
    _(defaultFollows).each(function(pair) {
      following.push({"name": pair[0], "id": pair[1] })
    });
    store.set("following", following);

    navigator.geolocation.getCurrentPosition(gotLocation);

  } else {
    $('span#following_tip').text("Loaded your saved follow list...");
    $('article#geolocationPrompt').hide();
    loadFollowing();
  }

});

var loadFollowing = function() {

  var following_ul = $('ul#following');

  _(store.get("following")).each(function(publisher) {
    following_ul.append('<li><a href="#">' + publisher["name"] + '</a><a class="delete" href="#">Delete</a><div class="clear"></div></li>');
  });

  backfillStream();
}

var backfillStream = function() {
  var backfillSocket = new WebSocket("ws://localhost:8080/backfill");
  backfillSocket.onopen = function() {
    var following_ids = _(store.get("following")).map(function(obj) {
      return obj['id'];
    });
    requestObject = {'since':'0', 'following_ids':following_ids};
    backfillSocket.send(JSON.stringify(requestObject));
  };

  backfillSocket.onmessage = function(payload) {
    addToStream(JSON.parse(payload.data).reverse());
  };
}

var addToStream = function(activities) {
  _(activities).each(function(activity) {
    activityQueue.push(activity);
  });
}