namespace :load do
  
  desc "Load all legislators"
  task :legislators do
    FasterCSV.foreach(Rails.root + "data/legislators.csv", :headers => :first_row) do |row|
      if row["in_office"] == '1'
        Publisher.create!(:name => common_name(row),
                          :publisher_type => "member",
                          :description => "#{row["party"]}-#{row["state"]}",
                          :title => row["title"],
                          :party => row["party"],
                          :bioguide_id => row["bioguide_id"],
                          :govtrack_id => row["govtrack_id"],
                          :twitter_id => row["twitter_id"],
                          :youtube_id => youtube_id(row["youtube_url"]))
      end
    end
  end
  
  task :other_publishers do
    YAML.load_file(Rails.root + "data/publishers.yml").each do |entry|
      publisher = entry[1]
      Publisher.create!(:name => publisher["name"],
                        :publisher_type => publisher["publisher_type"])
    end
  
  end
  
  
  def common_name(row)
    (row["nickname"].empty? ? row["firstname"] : row["nickname"]) + " " + row["lastname"]
  end

  def youtube_id(url)
    url.split('/').last
  end
  
end