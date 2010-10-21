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
      render Activity.any_in(:publisher_ids => request["following_ids"]).
                      desc(:created_at).
                      limit(30).
                      to_json
    end
    
  end

  class LiveSocket < Cramp::Websocket
    @@users = Set.new

    on_start :user_connected
    on_finish :user_left
    periodic_timer :new_activities, :every => 5
    
    def user_connected
      @@users << self
    end

    def user_left
      @@users.delete self
    end

    def new_activities
      #@@users.each {|u| u.render data }
    end
  end
end


routes = Usher::Interface.for(:rack) do
  add('/backfill').to(SocketServer::BackfillSocket)
  add('/live').to(SocketServer::LiveSocket)
end

Rack::Handler::Thin.run routes, :Port => 8080