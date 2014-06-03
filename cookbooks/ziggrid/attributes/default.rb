default[:ziggrid][:user] = "ziggrid"
default[:ziggrid][:group] = "ziggrid"

default[:ziggrid][:deploy_dir] = "/opt/ziggrid"

default[:ziggrid][:prod][:filename] = "20130812-ziggrid.zip"
default[:ziggrid][:prod][:prefix] = "/autobuild"
default[:ziggrid][:prod][:bucket] = "ziniki"

default[:ziggrid][:static][:filename] = "ziggrid_static.zip"
default[:ziggrid][:static][:bucket] = "ziggrid"

default[:ziggrid][:aws][:access_key] = "your_access_key"
default[:ziggrid][:aws][:secret_key] = "your_secret_key"

default[:ziggrid][:config_zip_list] = ["ziggrid-baseball.zip"]
default[:ziggrid][:bucket_name] = "ziggrid-baseball"

default[:ziggrid][:data][:filename] = "baseballData.zip"
default[:ziggrid][:data][:bucket] = "ziggrid"

default[:ziggrid][:use_graphite] = false

default[:ziggrid][:debug] = false
default[:ziggrid][:use_logstash] = false

default[:ziggrid][:collect_metrics] = false

default[:ziggrid][:webserver][:port] = 8088

default[:ziggrid][:data][:datastore] = "foundationdb"

default[:ziggrid][:role] = "none"

default[:ziggrid][:data][:clearDB] = false
