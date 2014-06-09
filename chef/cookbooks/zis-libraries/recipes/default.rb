#
# Cookbook Name:: zis-libraries
# Recipe:: default
#
# Copyright (C) 2014 Ziniki Infrastructure Software
# 
# All rights reserved - Do Not Redistribute
#

class Chef::Recipe::Namespace
  include Coordinator
end

class Chef::Resource::Namespace
  include Coordinator
end

class Chef::Recipe
  include ZinikiUtils
end

class Chef::Resource
  include ZinikiUtils
end
