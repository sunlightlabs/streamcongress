require 'twitter'

namespace :fetch do

  desc "Load recent tweets"
  task :tweets do

    keys = YAML.load_file(Rails.root + "config/keys.yml")
    oauth = Twitter::OAuth.new(keys["twitter"]["consumer_token"], keys["twitter"]["consumer_secret"])
    oauth.authorize_from_access(keys["twitter"]["access_token"], keys["twitter"]["access_secret"])
    client = Twitter::Base.new(oauth)

    if last = Activity.last(:conditions => { :source_name => "twitter" })
      last_id = last.source_id
    else
      last_id = 0
    end
    
    senate_tweets = Publisher.first(:conditions => {:name => "Senate Tweets"})
    house_tweets = Publisher.first(:conditions => {:name => "House Tweets"})
    
    client.friends_timeline(:count => 200, :since => last_id).each  do |tweet|
      unless Activity.first(:conditions => {:source_name => "twitter", :source_id => tweet.id})
        if publisher = Publisher.first(:conditions => {:twitter_id => tweet.user.screen_name})

          tweetstream = publisher.title == 'Sen' ? senate_tweets : house_tweets
          Activity.create!(:main_content => tweet.text,
                           :source_name => "twitter",
                           :source_id => tweet.id,
                           :source_url => "http://twitter.com/" + tweet.user.screen_name + "/status/" + tweet.id.to_s,
                           :publishers => [publisher, tweetstream])
          puts "New Tweet: " + tweet.id.to_s
        end
      end
    end

  end

end