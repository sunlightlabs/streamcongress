module ApplicationHelper

  def signed_in?
    !session[:user_id].nil?
  end
  
  def current_user
    @current_user ||= Subscriber.first(:conditions => {:id => session[:user_id]})
  end

end
