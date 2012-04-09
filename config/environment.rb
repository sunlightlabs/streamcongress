# Force syck over psych
require 'yaml'
(YAML::ENGINE.yamler = 'syck') rescue nil

# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Streamcongress::Application.initialize!
