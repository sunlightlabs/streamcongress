require 'httparty'

class YouTube
  include HTTParty
  format :json
  
  def self.latest_videos(youtube_id)
    get("http://gdata.youtube.com/feeds/api/users/#{youtube_id}/uploads?v=2&alt=jsonc&max-results=10")
  end
end

namespace :fetch do
  
  desc "Load recent YouTube videos"
  task :videos do
    
    Publisher.all(:conditions => {:minute_id => Time.now.min}).each do |member|
      if member.youtube_id
        videos = YouTube.latest_videos(member.youtube_id).parsed_response["data"]["items"]
        videos.each do |video|
          unless Activity.first(:conditions => {:source_name => "youtube", :source_id => video["id"]})
            if publisher = Publisher.first(:conditions => {:youtube_id => video["uploader"]})

              Activity.create!(:main_content => video["title"],
                               :secondary_content => video["description"],
                               :source_name => "youtube",
                               :source_id => video["id"],
                               :source_url => "http://www.youtube.com/watch?v=" + video["id"],
                               :publishers => [publisher])
              puts "New YouTube video: " + video["id"]
            end
          end
        end
      end
    end
    
  end
  
end