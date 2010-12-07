class Comment
  
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :body
  field :subscriber_id
  field :display_name
  
  embedded_in :activity, :inverse_of => :comments
end