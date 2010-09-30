class Publisher

  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name
  field :publisher_type
  field :description
  
  field :title
  field :party
  field :bioguide_id
  field :govtrack_id
  field :twitter_id
  field :youtube_id
  
  validates_presence_of :name
  validates_presence_of :publisher_type
  
  validates_inclusion_of :publisher_type, :in => ["member", "group", "app"]

  referenced_in :activity
  
end
