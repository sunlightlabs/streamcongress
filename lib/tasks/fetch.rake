namespace :fetch do

  desc "Fetch all data sources"
  task :all => [:tweets, :videos, :news]

end