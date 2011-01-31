require 'monster_mash'
require 'hashie'

class RealTimeCongress < MonsterMash::Base
  BASE = 'http://api.realtimecongress.com/api/v1/'
  APIKEY = '4eb10599f1c947868810783a5f4fd50a'

  defaults do
    params 'apikey' => APIKEY
  end

  get(:floor_updates) do
    uri "#{BASE}/floor_updates.json"
    handler do |response|
      JSON.parse(response.body)["floor_updates"].map { |u| Hashie::Mash.new(u) }
    end
  end
end

namespace :fetch do

  desc "Load floor updates"
  task :floor_updates do

    house_floor = Publisher.first(:conditions => {:name => "House Floor"})
    senate_floor = Publisher.first(:conditions => {:name => "Senate Floor"})

    RealTimeCongress.floor_updates.each do |update|
      source_id = update.timestamp + update.chamber
      source_url = ""
      source_content = update.events.join(" ")
      if Activity.first(:conditions => {:source_id => source_id})
        break
      else
        if update.legislator_ids
          publishers = update.legislator_ids.map do |bioguide_id|
            Publisher.first(:conditions => {:bioguide_id => bioguide_id})
          end
        else
          publishers = []
        end
        if update.chamber == "house"
          publishers << house_floor
          source_url = "http://clerk.house.gov/floorsummary/floor.html"
        elsif update.chamber == "senate"
          publishers << senate_floor
          source_url = "http://republican.senate.gov/public/index.cfm?FuseAction=FloorUpdates.Browse"
          source_content = "Spoke: " + source_content unless source_content =~ /Opening|Results/
        end
        puts "Creating #{source_id}"
        Activity.create!(:source_id => source_id,
                        :main_content => source_content,
                        :source_name => "#{update.chamber} floor",
                        :source_url => source_url,
                        :publishers => publishers)
      end
    end # RealTimeCongress.floor_updates.each
  end # task :floor_updates
end # namespace fetch
