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

  def all_member_ids
     Publisher.where(:publisher_type => "member").map do |member|
       [member.id.to_s,
        "#{member.title}. #{member.name} (#{member.party})",
        member.bioguide_id]
     end
  end

  def all_member_names
    Publisher.where(:publisher_type => "member").map do |member|
      "#{member.name} (#{member.state}-#{member.district})"
    end
  end

  def member_name_lookup
    hash = Hash.new
    Publisher.where(:publisher_type => "member").map do |member|
      hash["#{member.name} (#{member.state}-#{member.district})"] = { "name" => "#{member.title}. #{member.name} (#{member.party})",
                                                                      "id" => member.id.to_s }
    end
    hash
  end

  def slug_lookup
    hash = Hash.new
    Publisher.all.map do |p|
      hash[p.id.to_s] = p.slug
    end
    hash
  end

end
