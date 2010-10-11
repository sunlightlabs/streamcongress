class Subscriber
  include Mongoid::Document
  
  field :display_name
  field :email
  field :identifier_url

  index :email
  index :identifier_url
  
  validates_presence_of :display_name
  validates_presence_of :email
  validates_presence_of :identifier_url

end
