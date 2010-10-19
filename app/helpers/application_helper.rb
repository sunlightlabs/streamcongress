module ApplicationHelper

  def signed_in?
    !session[:user_id].nil?
  end
  
  def current_user
    @current_user ||= Subscriber.first(:conditions => {:id => session[:user_id]})
  end

  def default_follows
    Publisher.where(:publisher_type => "group").order_by(:name.asc).map do |pub| 
      [pub.name, pub.id.to_s]
    end
  end
  
  def all_members
     Publisher.where(:publisher_type => "member").map do |member|
       [member.bioguide_id,
        "#{member.title}. #{member.name} (#{member.party})",
        member.id.to_s]
     end
  end
  
end
