require 'twitter'


namespace :load do
  desc "Follow Twitter accounts"
  task :twitter_accounts do

    keys = YAML.load_file(Rails.root + "config/keys.yml")
    oauth = Twitter::OAuth.new(keys["twitter"]["consumer_token"], keys["twitter"]["consumer_secret"])
    oauth.authorize_from_access(keys["twitter"]["access_token"], keys["twitter"]["access_secret"])
    client = Twitter::Base.new(oauth)

    Publisher.active_members.each do |member|
      unless member.twitter_id.blank?
        begin
          client.friendship_create(member.twitter_id)
          puts "Followed #{member.twitter_id}"
        rescue
          puts "Already following #{member.twitter_id}"
        end
      end
    end
  end
end

namespace :fetch do

  desc "Load recent tweets"
  task :tweets => :environment do

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
        if publisher = Publisher.first(:conditions => {:twitter_id => tweet.user.screen_name, :in_office => true})

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
