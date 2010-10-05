require File.expand_path('../boot', __FILE__)

require "action_controller/railtie"
require "action_mailer/railtie"
require 'mongoid/railtie'
require 'rack/openid'

Bundler.require(:default, Rails.env) if defined?(Bundler)

module Streamcongress
  class Application < Rails::Application
    config.encoding = "utf-8"
    config.middleware.use 'Rack::OpenID'
  end
end
