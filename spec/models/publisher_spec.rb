require 'spec_helper'

describe Publisher do
  
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:publisher_type) }
  
  it { should validate_uniqueness_of(:name) }

  it { should validate_inclusion_of(:publisher_type).to_allow("senator",
                                                              "representative",
                                                              "chamber") }
end
