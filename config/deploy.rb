set :environment, (ENV['target'] || 'staging')

set :user, 'streamcongress'
set :application, user
set :deploy_to, "/home/streamcongress/www"

if environment == 'production'
  set :domain, "streamcongress.com"
else
  set :domain, "staging.streamcongress.com"
end

set :repository,  "git@github.com:sunlightlabs/streamcongress.git"
set :scm, 'git'
set :use_sudo, false
set :deploy_via, :remote_cache

role :web, domain
role :app, domain
role :db,  domain, :primary => true 

after "deploy", "deploy:cleanup"

namespace :deploy do
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end
  
  
  task :symlink_config do
    run "ln -s #{shared_path}/config/keys.yml #{release_path}/config/keys.yml"
    run "ln -s #{shared_path}/config/mongoid.yml #{release_path}/config/mongoid.yml"
  end
end

# namespace :bundler do
#   task :install do
#     run("gem install bundler")
#   end
# 
#   task :symlink_vendor do
#     shared_gems = "#{shared_path}/vendor/gems"
#     release_gems = "#{release_path}/vendor/gems"
#     run("mkdir -p #{shared_gems} && mkdir -p #{release_gems} && rm -rf #{release_gems} && ln -s #{shared_gems} #{release_gems}")
#   end
# 
# end
# 
# after 'deploy:update_code' do
#   bundle.install
#  deploy.symlink_config
#end