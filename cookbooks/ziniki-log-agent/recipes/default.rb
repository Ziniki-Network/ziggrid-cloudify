#
# Cookbook Name:: ziniki-log-agent
# Recipe:: default
#
# Copyright (C) 2014 Ziniki Infrastructure Software
# 
# All rights reserved - Do Not Redistribute
#

include_recipe "zis-libraries"

node.override['logstash']['install_zeromq'] = true
node.override['logstash']['agent']['config_file'] = ""
node.override['logstash']['agent']['config_templates'] = ["agent"]
node.override['logstash']['agent']['config_templates_cookbook'] = 'ziniki-log-agent'
node.override['logstash']['agent']['config_templates_variables'] = { "agent" => { "logstash_server_ip" => "#{Coordinator.waitForLogstashServer(node)}" } }

addNodeNameToLogstashAgent()  

include_recipe "logstash::agent"