#
# Cookbook Name:: foundationdb::server
# Recipe:: default
#
# Copyright (C) 2014 Eric Diamond
# 

include_recipe "zis-libraries"
include_recipe "foundationdb::shared"

service "foundationdb" do
  supports :status => true, :restart => true, :reload => true
end

ruby_block "Announce that this node is not ready" do
  block do
    node.set['foundationdb']['is_node_ready'] = false
    node.save
  end
end

service "foundationdb" do
  action :stop
end

# download foundation db clients
remote_file File.join(Chef::Config[:file_cache_path], node['foundationdb']['client_download_package_name']) do
  source node['foundationdb']['client_download_full_url']
  action :create_if_missing
end

# download foundation db server
remote_file File.join(Chef::Config[:file_cache_path], node['foundationdb']['server_download_package_name']) do
  source node['foundationdb']['server_download_full_url']
  action :create_if_missing
end

# install server
rpm_package "foundationdb-server" do
  action :install
  options "--nodeps"
  source File.join(Chef::Config[:file_cache_path], node['foundationdb']['server_download_package_name'])
end

# install clients
rpm_package "foundationdb-clients" do
  action :install
  options "--nodeps"
  source File.join(Chef::Config[:file_cache_path], node['foundationdb']['client_download_package_name'])
end

ruby_block "Set the trailblazer IP address" do
  block do
    node.set['foundationdb']['trailblazer_ip'] = Coordinator.waitForFoundation(node)
  end
end

#configure fdb.cluster
template File.join("etc", "foundationdb", "fdb.cluster") do
  source "fdb.cluster.erb"
  mode 0644
  owner node[:foundationdb][:user]
  group node[:foundationdb][:group]
  variables lazy {
    {
      coordination_server: node['foundationdb']['trailblazer_ip'] 
    }
  }
end

#change the data and log directory (in /etc/foundationdb/foundation.conf) to an ephermeral drive if appropriate attribute is set
if node['foundationdb']['storage_engine'] == "ssd"
  #stop the foundationdb service
  service "foundationdb" do
    action :stop
  end

  #create the mount point
  directory node['foundationdb']['base_disk_path'] do
    mode 0744
    owner node[:foundationdb][:user]
    group node[:foundationdb][:group]
    action :create
  end

  #format the filesystem if the ssd device is not set up
  bash "Create ext4 filesystem if not present" do
    code "mkfs.ext4 #{node['foundationdb']['block_device']}"
    not_if "blkid | grep #{node['foundationdb']['block_device']}"
  end

  #mount the drive if it isn't mounted
  mount node['foundationdb']['base_disk_path'] do
    device node['foundationdb']['block_device']
    fstype "ext4"
    not_if "cat /proc/mounts | grep #{node['foundationdb']['base_disk_path']}"
  end

  #create the foundationdb directory
  directory node['foundationdb']['foundation_path'] do
    mode 0744
    owner node[:foundationdb][:user]
    group node[:foundationdb][:group]
    action :create
  end

  # #create the /data directory
  # directory node['foundationdb']['data_path'] do
  #   mode 0744
  #   owner node[:foundationdb][:user]
  #   group node[:foundationdb][:group]
  #   action :create
  # end

  # directory File.join(node['foundationdb']['data_path'], node['foundationdb']['port'].to_s) do
  #   mode 0744
  #   owner node[:foundationdb][:user]
  #   group node[:foundationdb][:group]
  #   action :create
  #   recursive true
  # end

  # directory node['foundationdb']['log_path'] do
  #   mode 0744
  #   owner node[:foundationdb][:user]
  #   group node[:foundationdb][:group]
  #   action :create
  #   recursive true
  # end

  #configure foundationdb.conf
  template File.join("etc", "foundationdb", "foundationdb.conf") do
    source "foundationdb.conf.erb"
    owner node[:foundationdb][:user]
    group node[:foundationdb][:group]
    mode 0644
  end
end

service "foundationdb" do
  action :restart
end

if node.role?("foundationdb-trailblazer")

  #define a new database
  bash "Configure a new database" do
    group node[:foundationdb][:group]
    user node[:foundationdb][:user]
    #cwd releaseDir
    code "fdbcli --exec 'configure new #{node['foundationdb']['redundancy_mode']} #{node['foundationdb']['storage_engine']}'"
  end

end

ruby_block "Announce that this node is ready" do
  block do
    node.set['foundationdb']['is_node_ready'] = true
    node.save
  end
end

#adjust the coordination server count
bash "Modify coordination server list" do
  group node[:foundationdb][:group]
  user node[:foundationdb][:user]
  code lazy { "fdbcli --exec 'coordinators #{Coordinator.collectFoundationCoordinators(node)}'" }
end



