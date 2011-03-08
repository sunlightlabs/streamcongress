class Activity

  include Mongoid::Document
  include Mongoid::Timestamps

  field :main_content
  field :secondary_content
  field :source_name
  field :source_id
  field :source_url

  embeds_many :comments

  index :source_id
  index([[:source_name, Mongo::ASCENDING], [:source_id, Mongo::ASCENDING]])
  index :created_at
  index :updated_at

  #references_many :publishers, :stored_as => :array, :index => true
  references_and_referenced_in_many :publishers, :index => true
  validates_presence_of :main_content
  validates_presence_of :source_name
  validates_presence_of :source_id
  validates_presence_of :source_url

end
