$(function() {

  $("#activityTemplate").template("activity");

  $("input#memberSearch").autocomplete(allMemberNames, {  matchContains : true,
                                                          cacheLength   : 50,
                                                          max           : 20 });

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

//
// Grab follow list and recent activities from local storage
//
var loadStored = function() {

  var followingList = $('ul#following');
  _(store.get("following")).each(function(publisher) {
    followingList.append('<li><a href="#">' + publisher["name"] + '</a><a class="delete" href="#" data-id="' + publisher["id"] + '">Delete</a><div class="clear"></div></li>');
  });

  $('ul#following li').mouseover(function() {
    $(this).children('a.delete').show();
  });
  $('ul#following li').mouseleave(function() {
    $(this).children('a.delete').hide();
  });
  $('ul#following li a.delete').click(function() {
    var clicked = $(this);
    var updatedList = _(store.get("following")).reject(function(publisher) {
      return (publisher["id"] == clicked.data('id'));
    });
    store.set("following", updatedList);
    clicked.parent().hide();
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

//
// Backfill the stream as appropriate
//
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
    liveStream();
  };
};

//
// Connect to the live stream
//
var liveStream = function() {
  var liveSocket = new WebSocket("ws://" + socketDomain + ":8080/live");
  liveSocket.onmessage = function(payload) {
    addToStream(JSON.parse(payload.data).reverse());
  };
};

//
// Add activities to the in-memory queue
//
var addToStream = function(activities) {
  var memberLookup = {};
  _(allMemberIds).each(function(tuple) {
    memberLookup[tuple[0]] = { "name" : tuple[1], "bioguide_id" : tuple[2] };
  });
  _(activities).each(function(activity) {
    if (vetActivity(activity)) {
      publisherId = determinePublisher(activity.publisher_ids);
      activity["name"] = memberLookup[publisherId]["name"];
      activity["bioguide_id"] = memberLookup[publisherId]["bioguide_id"];
      activity["date"] = $.format.date(new Date(activity["created_at"]), "MM.dd.yyyy hh:mm a");
      var autolinkExpression = /((http|https|ftp):\/\/[\w?=&.\/-;#~%-]+(?![\w\s?&.\/;#~%"=-]*>))/g;
      activity["main_content"] = activity["main_content"].replace(autolinkExpression, '<a href="$1">$1</a> ');
      activityQueue.push(activity);
    }
  });
  if (activityQueue.length > 0 && !queueProcessing) {
    processQueue();
  }
};

//
// Render activities via jQuery templating
//
var processQueue = function() {
  var intervalId = setInterval(function() {
    queueProcessing = true;
    var activity = activityQueue.shift();
    if (!_(activity).isUndefined()) {
      var column = $("div#rtColumn_content");
      $.tmpl("activity", activity).fadeIn(1500).prependTo(column);
      addToRecentActivities(activity);
    } else {
      clearInterval(intervalId);
      queueProcessing = false;
    }
  }, 3500);
};

//
// Determine whether the activity should be displayed for this user
//
var vetActivity = function(activity) {
 var followingIds = _(store.get("following")).map(function(publisher) {
    return publisher["id"];
  });
 return _(activity.publisher_ids).detect(function(publisherId) {
   return _(followingIds).include(publisherId);
 });
}

//
// Determine the publisher (member of Congress) from publisher list
//
var determinePublisher = function(publisherIds) {
  return _(publisherIds).reject(function(publisherId) {
    return _(groupIds).include(publisherId);
  }).shift();
};

//
// Persist activities already displayed to user into local storage
//
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
