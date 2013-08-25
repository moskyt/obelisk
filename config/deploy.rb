require "bundler/capistrano"
load 'deploy/assets'

set :application, "obelisk"

set :scm, :git
set :repository, "git://github.com/moskyt/obelisk.git"
set :branch, "master"

# set :repository_cache, "git_cache"
# set :deploy_via, :remote_cache
set :git_shallow_clone, 1
set :ssh_options, { :forward_agent => true }
set :user, 'moskyt'
set :use_sudo, false

role :app, "siven.onesim.net"

role :web, "siven.onesim.net"
role :db,  "siven.onesim.net", :primary => true
set :deploy_to, "/home/moskyt/obelisk"

task :events do
  run "cd #{current_path}; bundle exec rake events:build RAILS_ENV=production"
end

namespace :deploy do
  task :restart do
    run "cd #{current_path}; touch tmp/restart.txt"
  end
end