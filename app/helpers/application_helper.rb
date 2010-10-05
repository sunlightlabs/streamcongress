module ApplicationHelper

  def signed_in?
    !session[:user_id].nil?
  end
  
  def current_user
    @current_user ||= Subscriber.first(:conditions => {:id => session[:user_id]})
  end
  
  def ensure_signed_in
    unless signed_in?
      session[:redirect_to] = request.request_uri
      redirect_to(auth_path)
    end
  end

end
