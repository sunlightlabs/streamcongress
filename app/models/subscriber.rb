class Subscriber
  include Mongoid::Document
  
  field :first_name
  field :last_name
  field :email
  field :identifier_url
  
  validates_presence_of :first_name
  validates_presence_of :last_name
  validates_presence_of :email
  validates_presence_of :identifier_url

  
  def display_name
    self.first_name + " " + self.last_name
  end
end
