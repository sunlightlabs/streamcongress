$(function() {

  $("#activityTemplate").template("activity");

  if (!signedIn && _(store.get("following")).isEmpty()) {

    var following = [];
    _(defaultFollows).each(function(pair) {
      following.push({"name": pair[0], "id": pair[1] })
    });
    store.set("following", following);

    navigator.geolocation.getCurrentPosition(gotLocation);

  } else {
    $('span#following_tip').text("Loaded your saved follow list...");
    $('article#geolocationPrompt').hide();
    loadStored();
  }

});

var loadStored = function() {

  var followingList = $('ul#following');
  _(store.get("following")).each(function(publisher) {
    followingList.append('<li><a href="#">' + publisher["name"] + '</a><a class="delete" href="#">Delete</a><div class="clear"></div></li>');
  });

  var streamColumn = $("div#rtColumn_content");
  var mostRecentActivity = { '_id': 0 };

  if (!_(store.get("recentActivities")).isUndefined()) {
    _(store.get("recentActivities")).each(function(activity) {
      $.tmpl("activity", activity).prependTo(streamColumn);
      mostRecentActivity = activity;
    });
  }

  backfillStream(mostRecentActivity);
};

var backfillStream = function(mostRecentActivity) {
  var backfillSocket = new WebSocket("ws://" + socketDomain + ":8080/backfill");
  var recentId = mostRecentActivity['_id'];
  backfillSocket.onopen = function() {
    var following_ids = _(store.get("following")).map(function(obj) {
      return obj['id'];
    });
    requestObject = { 'since_id':recentId, 'following_ids':following_ids };
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
      addToRecentActivities(activity);
    }
  }, 3500);
};

var determinePublisher = function(publisherIds) {
  return _(publisherIds).reject(function(publisherId) {
    return _(defaultFollows).include(publisherId);
  }).shift();
};

var addToRecentActivities = function(activity) {
  var recentActivities = store.get("recentActivities");
  if (_(recentActivities).isUndefined()) {
    recentActivities = [];
  }
  recentActivities.push(activity);
  if (recentActivities.length > 20) {
   recentActivities.shift();
  }
  store.set("recentActivities", recentActivities);
};