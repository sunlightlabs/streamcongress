class Publisher

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name
  field :publisher_type
  field :description

  field :title
  field :party
  field :state
  field :district
  field :slug
  field :bioguide_id
  field :govtrack_id
  field :twitter_id
  field :youtube_id
  field :in_office, :type => Boolean
  field :minute_id, :type => Integer

  index :publisher_type
  index :title
  index :party
  index :state
  index :slug
  index :bioguide_id
  index :govtrack_id
  index :twitter_id
  index :youtube_id
  index :in_office
  index :minute_id

  has_many :activities

  validates_presence_of :name
  validates_presence_of :publisher_type

  validates_inclusion_of :publisher_type, :in => ["member", "group", "app"]

  scope :active_members, :where => {:publisher_type => "member", :in_office => "true"}
end
