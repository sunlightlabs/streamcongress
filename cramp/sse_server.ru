require "rubygems"
require "bundler"
Bundler.require
require 'cramp'
require 'http_router'
require 'active_support/json'
require 'mongoid'
Mongoid.configure do |config|
  file_name = File.join(File.dirname(__FILE__), "..", "config", "mongoid.yml")
  settings = YAML.load(ERB.new(File.new(file_name).read).result)
  config.from_hash(settings[ENV["RACK_ENV"]])
end

Dir[File.expand_path("../../app/models/*.rb", __FILE__)].each  { |f| require f }

class LiveEvents < Cramp::Action
  self.transport = :sse

  periodic_timer :latest, :every => 30

  def latest
    @latest_id = BSON.ObjectId(params[:since_id]) if @latest_id.nil?
    puts @latest_id
    puts params[:following_ids]
    new_activities = Activity.where(:_id.gt => @latest_id).
                              any_in(:publisher_ids => params[:following_ids].split(',')).
                              desc(:_id)
    @latest_id = new_activities.first._id unless new_activities.empty?
    render new_activities.to_json
  end
end

routes = HttpRouter.new do
  add('/').to(LiveEvents)
end

# thin -R cramp/sse_server.ru start
run routes
