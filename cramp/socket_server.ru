require 'rubygems'
require 'bundler'
Bundler.require
require 'cramp'
require 'usher'
require 'mongoid'
require 'json'

Cramp::Websocket.backend = :thin
Mongoid.configure do |config|
  file_name = File.join(File.dirname(__FILE__), "..", "config", "mongoid.yml")
  settings = YAML.load(ERB.new(File.new(file_name).read).result)
  config.from_hash(settings[ENV["RACK_ENV"]])
end

Dir[File.expand_path("../../app/models/*.rb", __FILE__)].each  { |f| require f }


module SocketServer

  class BackfillSocket < Cramp::Websocket

    on_data :process_backfill

    def process_backfill(request_string)
      request = JSON.parse(request_string)
      if (request["since_id"] == 0)
        render Activity.any_in(:publisher_ids => request["following_ids"]).
                        desc(:_id).
                        limit(20).
                        to_json
      else
        render Activity.where(:_id.gt => BSON.ObjectId(request["since_id"])).
                        any_in(:publisher_ids => request["following_ids"]).
                        desc(:_id).
                        to_json
      end
    end

  end

  class LiveSocket < Cramp::Websocket
    @@users = Set.new

    on_start :user_connected
    on_finish :user_left
    periodic_timer :check_activities, :every => 5

    def user_connected
      @@users << self
      puts "New user!"
      puts "Count at " + @@users.length.to_s
    end

    def user_left
      @@users.delete self
      puts "User left------------------------------"
      puts "Count at " + @@users.length.to_s
    end

    def check_activities
      @latest_activity = Activity.new if @latest_activity.nil?
      new_activities = Activity.where(:_id.gt => @latest_activity._id).
                                desc(:_id)
      @latest_activity = new_activities.first unless new_activities.empty?
      render new_activities.to_json

    end
  end
end


routes = Usher::Interface.for(:rack) do
  add('/backfill').to(SocketServer::BackfillSocket)
  add('/live').to(SocketServer::LiveSocket)
end
run routes
# thin start --max-persistent-conns 10000 -R cramp/socket_server.ru
