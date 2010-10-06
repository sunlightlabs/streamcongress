class MainController < ApplicationController

  before_filter :ensure_signed_in, :only => [:settings]

  def index
    
  end
  
  def settings
    if subscriber = params[:subscriber] && !params[:subscriber][:display_name].blank?
      @subscriber.display_name = params[:subscriber][:display_name]
      @subscriber.save!
      redirect_to root_path
    end
  end
  
end