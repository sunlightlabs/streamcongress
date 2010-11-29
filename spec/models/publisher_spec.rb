require 'spec_helper'

describe Publisher do

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:publisher_type) }

  it { should validate_inclusion_of(:publisher_type).to_allow("member",
                                                              "group",
                                                              "app") }

  it { should have_fields(:title, :party, :bioguide_id, :govtrack_id, :twitter_id, :youtube_id, :minute_id)}

  it { should be_referenced_in(:activity) }

end
