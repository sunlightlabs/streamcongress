class Activity

  include Mongoid::Document
  include Mongoid::Timestamps

  field :main_content
  field :secondary_content
  field :source_name
  field :source_id
  field :source_type
  
  validates_presence_of :main_content
  validates_presence_of :source_name
  validates_presence_of :source_id
  validates_presence_of :source_url

  references_many :publishers, :stored_as => :array, :inverse_of => :activities
end
