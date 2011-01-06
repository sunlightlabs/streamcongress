namespace :load do

  desc "Load all legislators"
  task :legislators do
    FasterCSV.foreach(Rails.root + "data/legislators.csv", :headers => :first_row) do |row|

      # update existing
      if legislator = Publisher.first(:conditions => {:bioguide_id => row["bioguide_id"]})
        legislator.update_attributes!(:name => common_name(row),
                                      :description => "#{row["party"]}-#{row["state"]}",
                                      :title => row["title"],
                                      :party => row["party"],
                                      :state => row["state"],
                                      :district => format_district(row["district"]),
                                      :slug => "#{common_name(row)} #{row['state']} #{format_district(row['district'])}".parameterize,
                                      :bioguide_id => row["bioguide_id"],
                                      :govtrack_id => row["govtrack_id"],
                                      :twitter_id => row["twitter_id"],
                                      :youtube_id => youtube_id(row["youtube_url"]),
                                      :in_office => row["in_office"] == '1' ? true : false)

      elsif row["in_office"] == '1' # create new

        Publisher.create!(:name => common_name(row),
                          :publisher_type => "member",
                          :description => "#{row["party"]}-#{row["state"]}",
                          :title => row["title"],
                          :party => row["party"],
                          :state => row["state"],
                          :district => format_district(row["district"]),
                          :slug => "#{common_name(row)} #{row['state']} #{format_district(row['district'])}".parameterize,
                          :bioguide_id => row["bioguide_id"],
                          :govtrack_id => row["govtrack_id"],
                          :twitter_id => row["twitter_id"],
                          :youtube_id => youtube_id(row["youtube_url"]),
                          :in_office => row["in_office"] == '1' ? true : false,
                          :minute_id => rand(60))
      end
    end
  end

  desc "Assign minute_ids to legislators"
  task :legislator_minutes do
    Publisher.all(:conditions => {:publisher_type => "member"}).each do |member|
      member.update_attributes!(:minute_id => rand(60))
    end
  end

  desc "Load state/district for legislators"
  task :legislator_state do
    FasterCSV.foreach(Rails.root + "data/legislators.csv", :headers => :first_row) do |row|

      member = Publisher.first(:conditions => {:bioguide_id => row["bioguide_id"]})
      member.update_attributes!(:state => row["state"],
                                :district => format_district(row["district"])) unless member.nil?
    end
  end

  desc "Set slugs"
  task :slugs do
    Publisher.all.each do |p|
      if p.publisher_type == "member"
        p.update_attributes!(:slug => "#{p.name} #{p.state} #{p.district}".parameterize)
      else
        p.update_attributes!(:slug => p.name.parameterize)
      end
    end
  end

  desc "Load other publishers"
  task :other_publishers do
    YAML.load_file(Rails.root + "data/publishers.yml").each do |entry|
      publisher = entry[1]
      Publisher.create!(:name => publisher["name"],
                        :slug => publisher["name"].parameterize,
                        :publisher_type => publisher["publisher_type"])
    end
  end

  def common_name(row)
    (row["nickname"].empty? ? row["firstname"] : row["nickname"]) + " " + row["lastname"]
  end

  def youtube_id(url)
    url.split('/').last
  end

  def format_district(district)
    return "AL"           if district == "0"
    return "0" + district if district.length == 1
    return "SEN"          if district.length > 2
    return district
  end

end
