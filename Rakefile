require File.expand_path('../config/application', __FILE__)
require 'rake'
require 'mongoid'
Dir.glob(Rails.root + 'app/models/*.rb').each { |f| require f }

# Kill me
(YAML::ENGINE.yamler = 'syck') rescue nil
mongoid_conf = YAML::load_file(Rails.root.join('config/mongoid.yml'))[Rails.env]

Mongoid.configure do |config|
 config.skip_version_check = true
 config.master = Mongo::Connection.new(mongoid_conf['host'], 
                                       mongoid_conf['port']).db(mongoid_conf['database'])
end

Streamcongress::Application.load_tasks

