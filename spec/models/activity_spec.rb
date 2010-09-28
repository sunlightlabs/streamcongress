require 'spec_helper'

describe Activity do

  it { should validate_presence_of(:main_content) }

  it { should validate_presence_of(:source_name) }
  it { should validate_presence_of(:source_id) }
  it { should validate_presence_of(:source_url) }

  it { should reference_many(:publishers).stored_as(:array) }

  it { should have_field(:secondary_content) }
end
