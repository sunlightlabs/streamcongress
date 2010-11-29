class ApplicationController < ActionController::Base
  protect_from_forgery

  def signed_in?
    !session[:user_id].nil?
  end

  def ensure_signed_in
    unless signed_in?
      session[:redirect_to] = request.request_uri
      redirect_to(auth_path)
    end
    @subscriber = Subscriber.first(:conditions => { :id => session[:user_id] })
  end

end
