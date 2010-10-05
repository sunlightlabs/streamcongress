require 'spec_helper'

describe Subscriber do

  it { should validate_presence_of(:first_name) }
  it { should validate_presence_of(:last_name) }
  it { should validate_presence_of(:email) }
  it { should validate_presence_of(:identifier_url) }
  
  describe "#display_name" do
    it "should combine first name and last name into a string" do
      s = Subscriber.create!(:first_name => "John", :last_name => "Smith",
                             :email => "john@email.com", :identifier_url => "http://john.com")
      s.display_name.should == "John Smith"
    end
  end

end
