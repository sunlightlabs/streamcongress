require 'httparty'

class YahooNews
  include HTTParty
  format :json
  
  def self.latest_news(name)
    get("http://search.yahooapis.com/NewsSearchService/V1/newsSearch?appid=YMvFHb50&query=#{CGI::escape(name)}&results=10&language=en&output=json&sort=date&type=phrase")
  end
end

namespace :fetch do
  
  desc "Load recent news articles"
  task :news do
    
    hours = (0..23).to_a # uncomment when testing
    #hours = [5,7,9,10,12,14,15,17,19]
    if hours.include? Time.now.hour
      Publisher.all(:conditions => {:minute_id => Time.now.min}).each do |member|
        articles = YahooNews.latest_news(member.name).parsed_response["ResultSet"]["Result"]
        articles.each do |article|
          unless activity = Activity.first(:conditions => {:source_name => "news", :source_id => article["Url"]})
            Activity.create!(:main_content => article["Title"],
                             :secondary_content => article["Summary"],
                             :source_name => "news",
                             :source_id => article["Url"],
                             :source_url => article["Url"],
                             :publishers => [member])
            puts "New news hit: " + article["Url"]
          else 
            unless activity.publishers.include? member
              puts "Adding " + member.name
              activity.publishers << member
              activity.save!
              puts "Added!"
              puts "Count: " + activity.publishers.count.to_s
              puts "Updated news hit: " + article["Url"] + " for " + member.name
              activity.publishers.each do |p|
                puts p.name
              end
            end
          end # unless Activity
        end # news.each
      end # Publisher.all
    end # hours.include?
  end
  
end