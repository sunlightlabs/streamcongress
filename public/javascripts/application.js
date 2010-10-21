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
};

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
};

var addToStream = function(activities) {

  var memberLookup = {};
  _(allMemberIds).each(function(tuple) {
    memberLookup[tuple[0]] = { "name" : tuple[1], "bioguide_id" : tuple[2] };
  });
  console.log(memberLookup);

  _(activities).each(function(activity) {
    publisherId = determinePublisher(activity.publisher_ids);
    activity["name"] = memberLookup[publisherId]["name"];
    activity["bioguide_id"] = memberLookup[publisherId]["bioguide_id"];
    activity["date"] = $.format.date(new Date(activity["created_at"]), "MM.dd.yyyy hh:mm a");
    activityQueue.push(activity);
  });
  processQueue();
};

var processQueue = function() {
  setInterval(function() {
    var activity = activityQueue.shift();
    if (!_(activity).isUndefined()) {
      var column = $("div#rtColumn_content");
      $.tmpl("activity", activity).fadeIn(1500).prependTo(column);
    }
  }, 3500);
};

var determinePublisher = function(publisherIds) {
  return _(publisherIds).reject(function(publisherId) {
    return (_(_(store.get("following")).map((function(f){ return f.id; }))).include(publisherId) ||
           _(defaultFollows).include(publisherId));
  }).shift();
};