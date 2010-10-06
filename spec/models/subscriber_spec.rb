require 'spec_helper'

describe Subscriber do

  it { should validate_presence_of(:display_name) }
  it { should validate_presence_of(:email) }
  it { should validate_presence_of(:identifier_url) }
  
end
