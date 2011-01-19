class MainController < ApplicationController

  before_filter :ensure_signed_in, :only => [:settings, :comment]
  #before_filter :user_agent_check, :except => [:chrome]

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

  def latest
    if params[:since_id] == 0
      @activities = Activity.any_in(:publisher_ids => params[:following_ids].split(',')).
                             desc(:_id).
                             limit(20)
    else
      @activities = Activity.where(:_id.gt => BSON.ObjectId(params[:since_id])).
                             any_in(:publisher_ids => params[:following_ids].split(',')).
                             desc(:_id)
    end
    render :json => @activities
  end

  def activity
    @activity = Activity.find(params[:id])
  end

  def comment
    @activity = Activity.find(params[:id])
    @activity.comments.create(:body => params[:body],
                              :subscriber_id => @subscriber.id,
                              :display_name => @subscriber.display_name)
    @activity.save
    redirect_to :back
  end

  def user_agent_check
    agent = Agent.new request.env["HTTP_USER_AGENT"]
    redirect_to chrome_path unless agent.name == :Chrome
  end

end
