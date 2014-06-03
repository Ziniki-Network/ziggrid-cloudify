name             'ziniki-log-agent'
maintainer       'Eric Diamond'
maintainer_email 'eric@ziniki.org'
license          'All rights reserved'
description      'Installs/Configures ziniki-log-agent'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends "logstash",		"= 0.8.1"
depends "partial_search", 	"= 1.0.6"
depends "zis-libraries", 	"= 0.1.0"
