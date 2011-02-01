var loadFollowing, loadStored, loadActivity, backfillStream, addToStream, processQueue, vetActivity, determinePublisher, addToRecentActivities, lamestamp, toTitleCase;
var backfilled = false;

$(function() {

  if (_.isUndefined(store.get('dbVersion'))) {
    store.set('dbVersion', 1);
  }

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
      following.push({"name": pair[0], "id": pair[1] });
    });
    store.set("following", following);

    navigator.geolocation.getCurrentPosition(gotLocation, noLocation);

  } else {
    // clean out following list
    var cleanFollowing = _(store.get("following")).reject(function(publisher) {
      return _.isUndefined(slugLookup[publisher.id]);
    });
    store.set("following", cleanFollowing);
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

loadFollowing = function() {
  var $followingList = $('ul#following');
  $followingList.empty();
  _(store.get("following")).each(function(publisher) {
    $followingList.append('<li><a href="/s/' + slugLookup[publisher.id] + '">' + publisher.name + '</a><a class="delete" href="#" data-id="' + publisher.id + '">Delete</a><div class="clear"></div></li>');
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
      return (publisher.id == clicked.data('id'));
    });
    store.set("following", updatedList);
    // TODO: Send a message to the websocket if logged in
    clicked.parent().hide();
  });
}

//
// Grab follow list and recent activities from local storage
//
loadStored = function() {

  var streamColumn = $("div#rtColumn_content");
  var mostRecentActivity = { '_id': 0 };

  var activitiesKey = "recentActivities";
  if (currentPage == "publisher") {
    activitiesKey = publisherSlug + "Activities";
  }

  if (!_(store.get(activitiesKey)).isUndefined()) {
    _(store.get(activitiesKey)).each(function(activity) {
      if (currentPage == "home") {
        var column = $("div#rtColumn_content");
        $.tmpl("activity", activity).fadeIn(1500).prependTo(column);
      } else if (currentPage == "publisher") {
        var $vcard = $("div#vcard");
        $.tmpl("activity", activity).fadeIn(1500).insertAfter($vcard);
      }
      mostRecentActivity = activity;
    });
  }

  backfillStream(mostRecentActivity);
};

//
// Load activity with comments
//
loadActivity = function() {
  var streamColumn = $("div#rtColumn_content");

  var memberLookup = {};
  _(allMemberIds).each(function(tuple) {
    memberLookup[tuple[0]] = { "name" : tuple[1], "bioguide_id" : tuple[2] };
  });

  publisherId = determinePublisher(activity.publisher_ids);
  activity.name = memberLookup[publisherId].name;
  activity.bioguide_id = memberLookup[publisherId].bioguide_id;
  activity.source_slug = slugLookup[publisherId];
  var createdDate = new Date(lamestamp(activity.created_at));
  activity.date = $.format.date(createdDate, "MM.dd.yyyy");
  activity.time = $.format.date(createdDate, "hh:mm a");
  var autolinkExpression = /((http|https|ftp):\/\/[\w?=&.\/\-;#~%\-]+(?![\w\s?&.\/;#~%"=\-]*>))/g;
  activity.main_content = activity.main_content.replace(autolinkExpression, '<a href="$1">$1</a> ');
  $("#activityTemplate").tmpl(activity).appendTo(streamColumn);
  $("#commentsTemplate").tmpl(activity).appendTo(streamColumn);
};

//
// Backfill the stream as appropriate
//
backfillStream = function(mostRecentActivity) {
  var sinceId = mostRecentActivity._id;
  var followingIds = '';
  _(store.get("following")).map(function(obj) {
    followingIds = followingIds + obj.id + ',';
  });
  if (currentPage == "publisher") {
    followingIds = publisherId;
  }
  var requestURL = '/latest?following_ids=' + followingIds + '&since_id=' + sinceId;
  $.getJSON(requestURL, function(data) {
    addToStream(data.reverse());
    setTimeout(function() {backfillStream(_(store.get('recentActivities')).last());}, 60000);
  });
};

//
// Add activities to the in-memory queue
//
addToStream = function(activities) {
  var memberLookup = {};
  _(allMemberIds).each(function(tuple) {
    memberLookup[tuple[0]] = { "name" : tuple[1], "bioguide_id" : tuple[2] };
  });
  _(activities).each(function(activity) {
    if (vetActivity(activity)) {
      if (activity.source_name == "house floor" || activity.source_name == "senate floor") {
        publisherId = _.last(activity.publisher_ids);
      } else {
        publisherId = determinePublisher(activity.publisher_ids);
      }
      if (!_.isUndefined(memberLookup[publisherId])) {
        activity.name = memberLookup[publisherId].name;
        activity.bioguide_id = memberLookup[publisherId].bioguide_id;
      } else {
        activity.name = toTitleCase(activity.source_name);
      }
      activity.source_slug = slugLookup[publisherId];
      var createdDate = new Date(lamestamp(activity.created_at));
      activity.date = $.format.date(createdDate, "MM.dd.yyyy");
      activity.time = $.format.date(createdDate, "hh:mm a");
      var autolinkExpression = /((http|https|ftp):\/\/[\w?=&.\/\-;#~%\-]+(?![\w\s?&.\/;#~%"=\-]*>))/g;
      activity.main_content = activity.main_content.replace(autolinkExpression, '<a href="$1">$1</a> ');
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
processQueue = function() {
  var rate = 3500;
  if (backfilled === false) {
    backfilled = true;
    rate = 1;
  }
  var intervalId = setInterval(function() {
    queueProcessing = true;
    var activity = activityQueue.shift();
    if (!_(activity).isUndefined()) {
      if (currentPage == "home") {
        var column = $("div#rtColumn_content");
        $.tmpl("activity", activity).fadeIn(1500).prependTo(column);
      } else if (currentPage == "publisher") {
        var $vcard = $("div#vcard");
        $.tmpl("activity", activity).fadeIn(1500).insertAfter($vcard);
      }

      addToRecentActivities(activity);
    } else {
      clearInterval(intervalId);
      queueProcessing = false;
    }
  }, rate);
};

//
// Determine whether the activity should be displayed for this user
//
vetActivity = function(activity) {
  var followingIds = _(store.get("following")).map(function(publisher) {
    return publisher.id;
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
determinePublisher = function(publisherIds) {
  return _(publisherIds).reject(function(publisherId) {
    return _(groupIds).include(publisherId);
  }).shift();
};

//
// Persist activities already displayed to user into local storage
//
addToRecentActivities = function(activity) {
  var activitiesKey = "recentActivities";
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

//
// Convert an ISO 8601 timestamp to a lame timestamp supported in older browsers
//
lamestamp = function(str) {
  return str.substr(5,2) + "/" + str.substr(8,2) + "/" + str.substr(0,4) + " " + str.substr(11,8) + " " + str.substr(19,3) + str.substr(23,2);
};

//
// Convert to Title Case
//
toTitleCase = function(str) {
    return str.replace(/\w\S*/g, function(txt){return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();});
};

