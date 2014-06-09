default['foundationdb']['user'] = "foundationdb"
default['foundationdb']['group'] = "foundationdb"

default['foundationdb']['download_base_url'] = "https://foundationdb.com/downloads/I_accept_the_FoundationDB_Community_License_Agreement"
default['foundationdb']['version'] = "2.0.7"

default['foundationdb']['server_download_package_name'] = "foundationdb-server-#{node['foundationdb']['version']}-1.x86_64.rpm"
default['foundationdb']['client_download_package_name'] = "foundationdb-clients-#{node['foundationdb']['version']}-1.x86_64.rpm"

default['foundationdb']['server_download_full_url'] = "#{node['foundationdb']['download_base_url']}/#{node['foundationdb']['version']}/#{node['foundationdb']['server_download_package_name']}"
default['foundationdb']['client_download_full_url'] = "#{node['foundationdb']['download_base_url']}/#{node['foundationdb']['version']}/#{node['foundationdb']['client_download_package_name']}"

default['foundationdb']['port'] = 4500

default['foundationdb']['cluster_name'] = "foundation_cluster"
default['foundationdb']['cluster_id'] = "potato42"

default['foundationdb']['redundancy_mode'] = "single"
default['foundationdb']['storage_engine'] = "memory"

default['foundationdb']['coordinator_count'] = 1
default['foundationdb']['is_node_ready'] = false

default['foundationdb']['block_device'] = "/dev/xvdb"

default['foundationdb']['base_disk_path'] = "/media/ephemeral0"
default['foundationdb']['foundation_path'] = "#{node['foundationdb']['base_disk_path']}/foundationdb"
default['foundationdb']['data_path'] = "#{node['foundationdb']['foundation_path']}/data"
default['foundationdb']['log_path'] = "#{node['foundationdb']['foundation_path']}/log"
