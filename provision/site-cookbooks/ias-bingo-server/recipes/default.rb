## Users ##

public_keys = data_bag_item('public_keys', 'keys')

user_id = node['ias-bingo-server']['user']['id']
home_dir = "/home/#{user_id}"

group user_id # create group if it does not exist

user user_id do
  shell '/bin/bash'
  group user_id
  supports :manage_home => true
  home home_dir
end

sudo user_id do
  group user_id
  nopasswd true

  commands [
    '/usr/sbin/service ias-bingo-server restart',
    '/usr/sbin/service ias-bingo-daemon restart'
  ]
end

directory home_dir+'/.ssh' do
  owner user_id
  group user_id
  mode '0700'
end

template "#{home_dir}/.ssh/authorized_keys" do
  source "authorized_keys.erb"
  owner user_id
  group user_id
  mode '0600'
  variables :keys => public_keys['values']
end

## MySQL ##

mysql2_chef_gem 'default' do
  action :install
end

mysql_password_config = Chef::EncryptedDataBagItem.load('passwords', 'mysql')
mysql_deploy_password = Chef::EncryptedDataBagItem.load('passwords', 'mysql_deploy')["value"]

mysql_service 'default' do
  version '5.6'
  bind_address '127.0.0.1'
  port '3306'
  initial_root_password mysql_password_config['password']
  action [:create, :start]
end

mysql_config 'default' do
  source 'ias-bingo-server.cnf.erb'
  notifies :restart, 'mysql_service[default]'
  action :create
end

mysql_connection_info = {
  :host     => '127.0.0.1',
  :port     => '3306',
  :username => 'root',
  :password => mysql_password_config['password']
}

config_database_name = node['ias-bingo-server']['database']['name']

mysql_database config_database_name do
  connection mysql_connection_info
  action :create
end

mysql_database_user user_id do
  connection mysql_connection_info
  password mysql_deploy_password
  database_name config_database_name
  action [:create, :grant]
end

bingo_sql_path = File.expand_path('../../templates/default/bingo.sql', __FILE__)

# run bingo.sql into mysql
# mysql_database config_database_name do
#   connection mysql_connection_info.merge(:database => config_database_name)
#   # database_name config_database_name
#   sql ::File.read(bingo_sql_path)
#   action :query
# end

## Application ##

include_recipe 'git'

v = {
  :app_root => "/u/apps/ias-bingo",
  :name => "ias-bingo"
}

directory v[:app_root] do
  owner "deploy"
  group "deploy"
  recursive true
end

directory v[:app_root] + "/shared/" do
  owner "deploy"
  group "deploy"
  recursive true
end

directory v[:app_root] + "/shared/log/" do
  owner "deploy"
  group "deploy"
  recursive true
end

git v[:app_root] + "/current" do
  repository "https://github.com/livlab/ias-bingo.git"
  reference "master"
  action :sync
end

twitter_config = Chef::EncryptedDataBagItem.load('credentials', 'twitter')

app_config = {
  "mysql"  => {
    "host" => "127.0.0.1",
    "port" => 3306,
    "user" => user_id,
    "password" => mysql_deploy_password,
    "database" => "ias_bingo_production"
  },
  "twitter"  => {
    "screen_name" => "iasBingo",
    "consumer_key" => twitter_config["consumer_key"],
    "consumer_secret" => twitter_config["consumer_secret"],
    "access_token" => twitter_config["access_token"],
    "access_token_secret" => twitter_config["access_token_secret"]
  }
}

file v[:app_root] + '/current/config.json' do
  owner user_id
  group user_id
  mode '0700'

  content app_config.to_json
end

## Python ##

include_recipe 'python'

virtual_env_path = v[:app_root] + '/shared/ve'

python_virtualenv virtual_env_path do
  owner user_id
  group user_id
  action :create
end

python_pip 'Flask' do
  version '0.10.1'
  virtualenv virtual_env_path
end

python_pip 'Jinja2' do
  version '2.7.3'
  virtualenv virtual_env_path
end

python_pip 'MarkupSafe' do
  version '0.23'
  virtualenv virtual_env_path
end

python_pip 'MySQL-python' do
  version '1.2.5'
  virtualenv virtual_env_path
end

python_pip 'Werkzeug' do
  version '0.9.6'
  virtualenv virtual_env_path
end

python_pip 'itsdangerous' do
  version '0.24'
  virtualenv virtual_env_path
end

python_pip 'python-dateutil' do
  version '2.2'
  virtualenv virtual_env_path
end

python_pip 'six' do
  version '1.6.1'
  virtualenv virtual_env_path
end

python_pip 'twitter' do
  version '1.14.3'
  virtualenv virtual_env_path
end

python_pip 'wsgiref' do
  version '0.1.2'
  virtualenv virtual_env_path
end

# figure out how to run website and daemon python scripts
template "/etc/init/ias-bingo-server.conf" do
  user "root"
  group "root"
  source "server.upstart.conf.erb"
  mode "0644"
end

template "/etc/init/ias-bingo-daemon.conf" do
  user "root"
  group "root"
  source "daemon.upstart.conf.erb"
  mode "0644"
end

## nginx ##

apt_repository 'nginx-ppa' do
  uri 'http://ppa.launchpad.net/nginx/stable/ubuntu'
  distribution node['lsb']['codename']
  components ['main']
  keyserver "keyserver.ubuntu.com"
  key 'C300EE8C'
end

include_recipe 'nginx'

nginx_config_path = "/etc/nginx/sites-available/#{v[:name]}"

template nginx_config_path do
  mode 0644
  source "nginx.conf.erb"
  variables v.merge(:server_names => "iasbingo.com")
  notifies :reload, "service[nginx]"
end

nginx_site v[:name] do
  config_path nginx_config_path
  enable true
end

nginx_site :default do
  enable false
end

package 'phantomjs' do
  not_if 'which phantomjs'
end