module ApplicationHelper

  def signed_in?
    !session[:user_id].nil?
  end
  
  def current_user
    @current_user ||= Subscriber.first(:conditions => {:id => session[:user_id]})
  end

  def default_follows
    Publisher.where(:publisher_type => "group").map{ |pub| [pub.name, pub.id.to_s] }
  end
  
end
