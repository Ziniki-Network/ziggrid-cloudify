#
# Cookbook Name:: foundationdb::client
# Recipe:: default
#
# Copyright (C) 2014 Eric Diamond
# 

include_recipe "zis-libraries"
include_recipe "foundationdb::shared"

group node[:foundationdb][:group]

user node[:foundationdb][:user] do
  group node[:foundationdb][:group]
  system true
  shell "/bin/bash"
end


# download foundation db clients
remote_file File.join(Chef::Config[:file_cache_path], node['foundationdb']['client_download_package_name']) do
  source node['foundationdb']['client_download_full_url']
  action :create_if_missing
end

directory node['foundationdb']['config_dir'] do
  mode 0755
  owner node[:foundationdb][:user]
  group node[:foundationdb][:group]
  action :create
  recursive true
end

# install clients
rpm_package "foundationdb-clients" do
  action :install
  options "--nodeps"
  source File.join(Chef::Config[:file_cache_path], node['foundationdb']['client_download_package_name'])
end

#wait for all of the foundationdb coordinators to come online


#configure fdb.cluster to include all coordinators
template File.join(node['foundationdb']['config_dir'], "fdb.cluster") do
  source "fdb.cluster.erb"
  mode 0644
  owner node[:foundationdb][:user]
  group node[:foundationdb][:group]
  variables lazy {
    {
      coordination_server: Coordinator.collectFoundationCoordinators(node) 
    }
  }
end



