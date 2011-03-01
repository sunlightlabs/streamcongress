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
     Publisher.active_members.map do |member|
       [member.bioguide_id,
        "#{member.title}. #{member.name} (#{member.party})",
        member.id.to_s]
     end
  end

  def all_member_ids
     Publisher.active_members.map do |member|
       [member.id.to_s,
        "#{member.title}. #{member.name} (#{member.party})",
        member.bioguide_id]
     end
  end

  def all_member_names
    Publisher.active_members.map do |member|
      "#{member.name} (#{member.state}-#{member.district})"
    end
  end

  def member_name_lookup
    hash = Hash.new
    Publisher.active_members.map do |member|
      hash["#{member.name} (#{member.state}-#{member.district})"] = { "name" => "#{member.title}. #{member.name} (#{member.party})",
                                                                      "id" => member.id.to_s }
    end
    hash
  end

  def slug_lookup
    hash = Hash.new
    Publisher.active_members.map do |p|
      hash[p.id.to_s] = p.slug
    end
    Publisher.where(:publisher_type => "group").map do |p|
      hash[p.id.to_s] = p.slug
    end
    hash
  end

  # Taken from the official published calendars and Roll Call
  # http://majorityleader.house.gov/Calendar/112th1stSessionCalendar.pdf
  # http://democrats.senate.gov/calendar/2011-01.html
  # http://cdn.rollcall.com/media/newspics/calendar120910.pdf
  def in_session?(chamber)
    calendar = { 'house' => { 1  => [5,6,7,11,12,18,19,20,24,25,26],
                              2  => [8,9,10,11,14,15,16,17,28],
                              3  => [1,2,3,8,9,10,11,14,15,16,17,29,30,31],
                              4  => [1,4,5,6,7,12,13,14,15],
                              5  => [2,3,4,5,10,11,12,13,23,24,25,26,31],
                              6  => [1,2,3,13,14,15,16,21,22,23,24],
                              7  => [6,7,8,11,12,13,14,15,25,26,27,28],
                              8  => [2,3,4,5],
                              9  => [7,8,9,12,13,14,15,20,21,22,23],
                              10 => [3,4,5,6,11,12,13,14,24,25,26,27],
                              11 => [1,2,3,4,14,15,16,17,18,29,30],
                              12 => [1,2,5,6,7,8]
                            },
                  'senate' => { 1  => [5,6,7,24,25,26,27,31],
                                2  => [1,2,3,4,7,8,10,14,15,16,17,28],
                                3  => [1,2,3,4,7,8,9,10,11,14,15,16,17,18,28,29,30,31],
                                4  => [1,4,5,6,7,8,11,12,13,14,15],
                                5  => [2,3,4,5,6,9,10,11,12,13,16,17,18,19,20,23,24,25,26,27],
                                6  => [6,7,8,9,10,13,14,15,16,17,20,21,22,23,24,27,28,29,30],
                                7  => [1,11,12,13,14,15,18,19,20,21,22,25,26,27,28,29],
                                8  => [1,2,3,4,5],
                                9  => [6,7,8,9,12,13,14,15,16,19,20,21,22,23,26,27,28,29,30],
                                10 => [3,4,5,6,7,11,12,13,14,17,18,19,20,21,31],
                                11 => [1,2,3,4,7,8,9,10,11,14,15,16,17,18,21,22,23,25,28,29,30],
                                12 => [1,2,5,6,7,8,9,12,13,14,15,16,19,20,21,22,23,26,27,28,29,30]
                            }
                }
    calendar[chamber.to_s.downcase][Time.now.month].include? Time.now.day
  end
end
