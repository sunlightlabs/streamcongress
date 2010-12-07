class MainController < ApplicationController

  before_filter :ensure_signed_in, :only => [:settings]
  before_filter :user_agent_check, :except => [:chrome]

  def index

  end

  def settings
    if subscriber = params[:subscriber] && !params[:subscriber][:display_name].blank?
      @subscriber.display_name = params[:subscriber][:display_name]
      @subscriber.save!
      redirect_to root_path
    end
  end

  def publisher
    @publisher = Publisher.where(:slug => params[:slug]).first
  end
  
  def activity
    @activity = Activity.find(params[:id])
  end
  
  def user_agent_check
    agent = Agent.new request.env["HTTP_USER_AGENT"]
    redirect_to chrome_path unless agent.name == :Chrome
  end
    
  
end
