$(function() {

  $("#activityTemplate").template("activity");

  // Set up the legislator search form
  $("input#memberSearch").autocomplete(allMemberNames, {  matchContains : true,
                                                          cacheLength   : 50,
                                                          max           : 20 });
  $("button#memberSearch").click(function() {
    var updatedList = store.get("following");
    var $input = $("input#memberSearch");
    updatedList.push(memberNameLookup[$input.attr("value")]);
    $input.attr("value", '');
    store.set("following", updatedList);
    loadFollowing();
    // TODO: Send a message to the websocket if logged in
  });

  // Set up the following list
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
    loadFollowing();
    if (currentPage == "home" || currentPage == "publisher") {
      loadStored();
    } else if (currentPage == "activity") {
      loadActivity();
    }
  }

});


//
// Load the following list in the sidebar
//

var loadFollowing = function() {
  var $followingList = $('ul#following');
  $followingList.empty();
  _(store.get("following")).each(function(publisher) {
    $followingList.append('<li><a href="/s/' + slugLookup[publisher["id"]] + '">' + publisher["name"] + '</a><a class="delete" href="#" data-id="' + publisher["id"] + '">Delete</a><div class="clear"></div></li>');
  });

  // Enable removal from following list
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
    // TODO: Send a message to the websocket if logged in
    clicked.parent().hide();
  });
}

//
// Grab follow list and recent activities from local storage
//
var loadStored = function() {

  var streamColumn = $("div#rtColumn_content");
  var mostRecentActivity = { '_id': 0 };

  var activitiesKey = "recentActivities"
  if (currentPage == "publisher") {
    activitiesKey = publisherSlug + "Activities";
  }

  if (!_(store.get(activitiesKey)).isUndefined()) {
    _(store.get(activitiesKey)).each(function(activity) {
      $.tmpl("activity", activity).prependTo(streamColumn);
      mostRecentActivity = activity;
    });
  }

  backfillStream(mostRecentActivity);
};

//
// Load activity with comments
//
var loadActivity = function() {
  var streamColumn = $("div#rtColumn_content");

  var memberLookup = {};
  _(allMemberIds).each(function(tuple) {
    memberLookup[tuple[0]] = { "name" : tuple[1], "bioguide_id" : tuple[2] };
  });

  publisherId = determinePublisher(activity["publisher_ids"]);
  activity["name"] = memberLookup[publisherId]["name"];
  activity["bioguide_id"] = memberLookup[publisherId]["bioguide_id"];
  activity["source_slug"] = slugLookup[publisherId];
  activity["date"] = $.format.date(new Date(activity["created_at"]), "MM.dd.yyyy");
  activity["time"] = $.format.date(new Date(activity["created_at"]), "hh:mm a");
  var autolinkExpression = /((http|https|ftp):\/\/[\w?=&.\/-;#~%-]+(?![\w\s?&.\/;#~%"=-]*>))/g;
  activity["main_content"] = activity["main_content"].replace(autolinkExpression, '<a href="$1">$1</a> ');

//  $.tmpl("activity", activity).appendTo(streamColumn);
  $("#activityTemplate").tmpl(activity).appendTo(streamColumn);
  $("#commentsTemplate").tmpl(activity).appendTo(streamColumn);
};

//
// Backfill the stream as appropriate
//
var backfillStream = function(mostRecentActivity) {
  var backfillSocket = new WebSocket("ws://" + socketDomain + ":8080/backfill");
  var recentId = mostRecentActivity['_id'];
  backfillSocket.onopen = function() {
    var followingIds = _(store.get("following")).map(function(obj) {
      return obj['id'];
    });
    if (currentPage == "publisher") {
      followingIds = [publisherId];
    }
    requestObject = { 'since_id':recentId, 'following_ids':followingIds };
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
      activity["source_slug"] = slugLookup[publisherId];
      activity["date"] = $.format.date(new Date(activity["created_at"]), "MM.dd.yyyy");
      activity["time"] = $.format.date(new Date(activity["created_at"]), "hh:mm a");
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
  if (currentPage == "publisher") {
    followingIds = [publisherId];
  }
  return _(activity.publisher_ids).detect(function(publisherId) {
    return _(followingIds).include(publisherId);
  });
}

//
// Determine the publisher (member of Congress) from publisher list
//
var determinePublisher = function(publisherIds) {
  console.log(publisherIds);
  return _(publisherIds).reject(function(publisherId) {
    return _(groupIds).include(publisherId);
  }).shift();
};

//
// Persist activities already displayed to user into local storage
//
var addToRecentActivities = function(activity) {
  var activitiesKey = "recentActivities"
  if (currentPage == "publisher") {
    activitiesKey = publisherSlug + "Activities";
  }
  var recentActivities = store.get(activitiesKey);

  if (_(recentActivities).isUndefined()) {
    recentActivities = [];
  }
  recentActivities.push(activity);
  if (recentActivities.length > 20) {
   recentActivities.shift();
  }
  store.set(activitiesKey, recentActivities);
};
