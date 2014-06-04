# Encoding: utf-8
name             'logstash'
maintainer       'John E. Vincent'
maintainer_email 'lusis.org+github.com@gmail.com'
license          'Apache 2.0'
description      'Installs/Configures logstash'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.8.1'

%w{ ubuntu debian redhat centos scientific amazon fedora }.each do |os|
  supports os
end

#removed rabbitmq from depends

%w{ build-essential git ant java logrotate  python }.each do |ckbk|
  depends ckbk
end

depends "yum",		"= 3.0.6"
depends "runit",	"= 1.5.10"

%w{ yum apt }.each do |ckbk|
  recommends ckbk
end