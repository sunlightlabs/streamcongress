class Publisher

  include Mongoid::Document

  field :name
  field :publisher_type
  field :description
  
  field :bioguide_id
  field :govtrack_id
  field :twitter_id
  field :youtube_id
  
  validates_presence_of :name
  validates_presence_of :publisher_type
  
  validates_uniqueness_of :name

  validates_inclusion_of :publisher_type, :in => ["senator", "representative", "chamber"]
end
