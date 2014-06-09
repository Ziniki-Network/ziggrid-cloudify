#
# Cookbook Name:: Ziggrid
# Recipe:: default
#
# Copyright (C) 2013 Ziniki Infrastructure Systems
# 

include_recipe "java"
include_recipe "runit"
include_recipe "zis-libraries"

if (node[:ziggrid][:data][:datastore] == "couchbase")
  if !node[:zinikicouch][:trailblazer][:is_elastic_ip]
    Coordinator.waitForCouchbase(node)
  end
elsif (node[:ziggrid][:data][:datastore] == "foundationdb")
  Coordinator.waitForFoundation(node)
end

if node[:ziggrid][:use_logstash]
  Chef::Log.info "Using logstash for log aggregation..."
  include_recipe "ziniki-log-agent"
else
  Chef::Log.info "Logstash integration is not being used..."
end

runit_service "ziggrid" do
  action :stop
end

group node[:ziggrid][:group]

user node[:ziggrid][:user] do
  group node[:ziggrid][:group]
  system true
  shell "/bin/bash"
end

# download ziggrid prod file only if it isn't already on the target system
local_prod_file = File.join(Chef::Config[:file_cache_path], node[:ziggrid][:prod][:filename])
local_static_file = File.join(Chef::Config[:file_cache_path], node[:ziggrid][:static][:filename])
local_config_file = "#{File.join(Chef::Config[:file_cache_path], node[:ziggrid][:role])}.config"
local_data_file = File.join(Chef::Config[:file_cache_path], node[:ziggrid][:data][:filename])

#ziggrid prod
s3_file local_prod_file do
  remote_path File.join(node[:ziggrid][:prod][:prefix], node[:ziggrid][:prod][:filename])
  bucket node[:ziggrid][:prod][:bucket]
  aws_access_key_id node[:ziggrid][:cloud][:aws][:access_key]
  aws_secret_access_key node[:ziggrid][:cloud][:aws][:secret_key]
  owner node[:ziggrid][:user]
  group node[:ziggrid][:group]
  mode "0755"
  action :create
end

#ziggrid static
s3_file local_static_file do
  remote_path "/#{node[:ziggrid][:static][:filename]}"
  bucket node[:ziggrid][:static][:bucket]
  aws_access_key_id node[:ziggrid][:cloud][:aws][:access_key]
  aws_secret_access_key node[:ziggrid][:cloud][:aws][:secret_key]
  owner node[:ziggrid][:user]
  group node[:ziggrid][:group]
  mode "0755"
  action :create
end

#download baseballData.zip
s3_file local_data_file do
  remote_path "/#{node[:ziggrid][:data][:filename]}"
  bucket node[:ziggrid][:data][:bucket]
  aws_access_key_id node[:ziggrid][:cloud][:aws][:access_key]
  aws_secret_access_key node[:ziggrid][:cloud][:aws][:secret_key]
  owner node[:ziggrid][:user]
  group node[:ziggrid][:group]
  mode "0755"
  action :create
end

deployDir = node[:ziggrid][:deploy_dir]
workingDir = "#{deployDir}"

directory "#{deployDir}" do
  mode 0755
  owner node[:ziggrid][:user]
  group node[:ziggrid][:group]
  action :create
  recursive true
end

%w{config logs scripts metrics data static}.each do |dir|
  directory File.join(deployDir, dir) do
    mode 0755
    owner node[:ziggrid][:user]
    group node[:ziggrid][:group]
    action :create
    recursive true
  end
end

#configure log4j.properties
template File.join(deployDir, "logs", "ziggrid-log4j.properties") do
  source "log4j.properties.erb"
  owner node[:ziggrid][:user]
  group node[:ziggrid][:group]
  mode 0644
  variables({
    :logFile           => File.join(deployDir, "logs", "ziggrid.log"),
  })
end

#ziggrid prod
execute "extract #{local_prod_file}" do
  command "unzip -q -u -o #{local_prod_file} -d #{deployDir}/.."
  user    node[:ziggrid][:user]
  group   node[:ziggrid][:group]
end

execute "extract #{local_static_file}" do
  command "unzip -q -u -o #{local_static_file} -d #{File.join(deployDir,"static")}"
  user    node[:ziggrid][:user]
  group   node[:ziggrid][:group]
end

execute "extract #{local_data_file}" do
  command "unzip -q -u -o #{local_data_file} -d #{File.join(deployDir,"data")}"
  user    node[:ziggrid][:user]
  group   node[:ziggrid][:group]
end

#download each file defined on the config zip list and expand them to the config directory
node[:ziggrid][:config_zip_list].each do |config_zip|
  
  config_zip_full_path = File.join(Chef::Config[:file_cache_path], config_zip)

  s3_file config_zip_full_path do
    remote_path "/#{config_zip}"
    bucket node[:ziggrid][:static][:bucket]
    aws_access_key_id node[:ziggrid][:cloud][:aws][:access_key]
    aws_secret_access_key node[:ziggrid][:cloud][:aws][:secret_key]
    owner node[:ziggrid][:user]
    group node[:ziggrid][:group]
    mode "0755"
    action :create
  end

  execute "extract #{config_zip_full_path}" do
    command "unzip -q -u -o #{config_zip_full_path} -d #{deployDir}/config"
    user    node[:ziggrid][:user]
    group   node[:ziggrid][:group]
  end

end

directory "#{workingDir}" do
  mode 0755
  owner node[:ziggrid][:user]
  group node[:ziggrid][:group]
  action :create
  recursive true
end

debugArguments = ""
if node[:ziggrid][:debug]
  Chef::Log.info "Putting debug arguments into cluster startup command"
  debugArguments = "-Xdebug -Xrunjdwp:server=y,transport=dt_socket,address=4026,suspend=n"
end

#configure ziggrid-baseball.xml
template File.join(deployDir, "config", "ziggrid-baseball.xml") do
  source "ziggrid-baseball.xml.erb"
  owner node[:ziggrid][:user]
  group node[:ziggrid][:group]
  mode 0644
  variables({
    :couchUrl         => node[:zinikicouch][:trailblazer][:is_elastic_ip] ? "http://#{node[:zinikicouch][:trailblazer][:domain_name]}:8091/" : node.run_state['couchbaseMainUrl'],
    :couchBucket      => node[:ziggrid][:bucket_name],
    :dataDirectory    => File.join(deployDir, "data")
  })
end

#Use the cloud public hostname if possible, but fallback to the ipaddress setting
endpoint = "Nothing"
if (node.attribute?(:cloud) && node[:cloud].attribute?(:public_ipv4))
  endpoint = node[:cloud][:public_ipv4]
  Chef::Log.info "Cloud attributes found, setting endpoint to #{endpoint}"
else
  endpoint = node[:ipaddress]
  Chef::Log.info "No cloud attributes found, setting endpoint to #{endpoint}"
end

if (node[:ziggrid][:data][:datastore] == "couchbase")
  couchbase_url=node[:zinikicouch][:trailblazer][:is_elastic_ip] ? "http://#{node[:zinikicouch][:trailblazer][:domain_name]}:8091/" : node.run_state['couchbaseMainUrl'],
  storage_options="--storage couchbase #{couchbase_url}"
elsif (node[:ziggrid][:data][:datastore] == "foundationdb")
  storage_options="--storage foundation #{clearDBString} --cluster /opt/ziggrid/config/fdb.cluster"

  include_recipe "foundationdb::client"

  #set up fdb config file
  s3_file local_config_file do
    remote_path "/#{node[:ziggrid][:prefix]}/#{node[:ziggrid][:role]}.config"
    bucket node[:ziggrid][:bucket]
    aws_access_key_id node[:ziggrid][:cloud][:aws][:access_key]
    aws_secret_access_key node[:ziggrid][:cloud][:aws][:secret_key]
    owner node[:ziggrid][:user]
    group node[:ziggrid][:group]
    mode "0755"
    action :create
  end

  clearDBString = ""
  if (node[:ziggrid][:data][:clearDB])
    clearDBString = "--clearDB"
   end
 
end

#set up command line
java_command_array = [  
"java",
"-cp '#{File.join(deployDir, "libs", "*")}'",
debugArguments,
"-Dlog4j.debug",
"-Dlog4j.configuration=file:#{File.join(deployDir, "logs", "ziggrid-log4j.properties")}",
"-Djava.util.logging.config.class=org.ziggrid.utils.http.LoggingConfiguration",
"-Dorg.ziniki.claim.endpoint=#{endpoint}",
"org.ziggrid.main.Ziggrid",                         
storage_options,
"--model #{File.join(deployDir,"config")} ziggrid-baseball",
"--web --static #{File.join(deployDir,"static")}",
"--file #{local_config_file}",
node[:ziggrid][:collect_metrics] ? "--metricsDir #{File.join(deployDir, "metrics")}" : "",
node[:ziggrid][:use_graphite] ? "--graphite #{node[:name]} #{Coordinator.findGraphite(node)}" : ""
]

java_command = java_command_array.join(' ')

Chef::Log.info "Configured Ziggrid start command as: #{java_command}"

runit_service "ziggrid" do
  default_logger true
  options({
    :clusterCommand  => java_command,
    :user            => node[:ziggrid][:user],
    :group           => node[:ziggrid][:group]
  })
end

runit_service 'ziggrid' do 
  action :restart
end