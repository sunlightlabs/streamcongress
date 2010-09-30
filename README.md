# Stream Congress

A realtime web application that helps constituents understand what their members of Congress are up to. A given entry in the stream can be from one of several sources:

* Votes on bills and resolutions
* Speaking appearances on the chamber floor
* Committee meetings
* Twitter tweets
* YouTube videos
* News mentions

## Set Up

Stream Congress is a Rails 3 app. It expects MongoDB, Ruby, RubyGems, and the Ruby gem called Bundler to be installed on your system.

    $ bundle install --binstubs
    $ bin/rails server

## Rake Tasks

The Rails app is the boring part. The slightly more interesting part is the set of Rake tasks that populate the database. The master task `fetch:all` is meant to be run once every minute.

    $ rake fetch:all
    $ rake fetch:floor_votes
    $ rake fetch:floor_updates
    $ rake fetch:committee_meetings
    $ rake fetch:tweets
    $ rake fetch:videos
    $ rake fetch:news

The YouTube videos and news mentions cycle through all members of Congress once per hour. They use the database to keep track of who's been already processed for the hour.

To initially populate the database with Publishers, run `rake load:legislators` and `rake load:other_publishers`.