# define a module to mix into Chef::Recipe

module Coordinator
  
  def self.waitForCouchbase(node)
    
    keys = nil

    if node[:zinikicouch][:trailblazer][:is_elastic_ip]
    	keys = { 'name' => [ 'name' ],
    		     'is_node_ready' => [ 'zinikicouch', 'is_node_ready'] }
		  query = "role:zinikicouch"
    else
	    keys = { 'name' => [ 'name' ],
	    		 'ip' => [ 'ipaddress' ],
		         'user' => [ 'couchbase', 'server', 'username' ],
		         'password' => [ 'couchbase', 'server', 'password' ],
		      	 'is_node_ready' => [ 'zinikicouch', 'is_node_ready'] }
		  query = "role:zinikicouch"
    end

    couchbaseInfoAll = waitForNodeQuery(query, keys, node)
    couchbaseInfo = couchbaseInfoAll.first
	
    if !node[:zinikicouch][:trailblazer][:is_elastic_ip]
      Chef::Log.info "couchbaseInfo = #{couchbaseInfo}"
      couchbaseIp = couchbaseInfo['ip']
      couchbaseMainUrl = "http://#{couchbaseIp}:8091/"
      couchbaseViewUrl = "http://#{couchbaseIp}:8092/"
      node.run_state['couchbaseMainUrl'] = couchbaseMainUrl
      node.run_state['couchbaseViewUrl'] = couchbaseViewUrl
      node.run_state['couchbaseInfo'] = couchbaseInfo
      Chef::Log.info "Found couchbase server at #{couchbaseIp}, setting #{node.run_state['couchbaseMainUrl']} as couchbaseUrl"
      Chef::Log.info "node.run_state: #{node.run_state}"
    end
  end

  def self.waitForCouchTrailblazer(node)
    keys = { 'is_node_ready' => [ 'zinikicouch', 'is_node_ready'],
               'ip' => [ 'ipaddress' ] }
    query = "role:zinikicouch-trailblazer"
    trailblazer_servers = waitForNodeQuery(query, keys, node)
    Chef::Log.info "Found trailblazer node at #{trailblazer_servers.first['ip']}"
    node.set['zinikicouch']['trailblazer']['ip'] = trailblazer_servers.first['ip']
    node.save
  end

  def self.waitForLogstashServer(node)
  	query = "role:logstash_server"
  	keys = { 'name' => [ 'name' ],
  		     'ip' => [ 'ipaddress' ] }
  	logstash_servers = waitForNodeQuery(query, keys, node)
  	node.run_state['logstashIp'] = logstash_servers.first['ip']
  	Chef::Log.info "Found logstash_server at #{logstash_servers.first['ip']}"
    return logstash_servers.first['ip']
  end

  def self.findGraphite(node)
    query = "role:zis-graphite"
    keys = { 'name' => [ 'name' ],
           'ip' => [ 'ipaddress' ],
           'port' => [ 'graphite', 'carbon', 'caches', 'a', 'line_receiver_port' ] }
    graphite_server = waitForNodeQuery(query, keys, node)
    graphite_collector_string = "#{graphite_servers.first['ip']} #{graphite_servers.first['port']}"
    Chef::Log.info "Found Graphite collector at #{graphite_collector_string}"
    return graphite_collector_string
  end

  def self.waitForFoundation(node)
  	query = "role:foundationdb-trailblazer"
  	keys = { 'name' => [ 'name' ],
  		     'ip' => [ 'ipaddress' ],
  		     'port' => [ 'foundationdb', 'port' ] }
  	servers = waitForNodeQuery(query, keys, node)
  	Chef::Log.info "Found foundationdb-trailblazer at #{servers.first['ip']}:#{node['foundationdb']['port']}"
    return "#{servers.first['ip']}:#{node['foundationdb']['port']}"
  end

  def self.collectFoundationCoordinators(node)
  	sleepTimer = 10
  	query = "role:foundationdb-coordinator"
  	keys = { 
              'name' => [ 'name' ],
  		        'ip' => [ 'ipaddress' ]
           }

  	servers = waitForNodeQuery(query, keys, node)
  	
  	servers.each do |server|
  		Chef::Log.info "Found server: #{server['name']} at #{server['ip']}"
  	end
  	
  	while(servers.count < node['foundationdb']['coordinator_count']) do
  		puts "Found #{servers.count} of #{node['foundationdb']['coordinator_count']} expected coordination servers. Sleeping #{sleepTimer} seconds..."
  		sleep sleepTimer
  		servers = waitForNodeQuery(query, keys, node)
  	end
  	
  	server_array = servers.collect {|server| "#{server['ip']}:#{node['foundationdb']['port']}" }
  	coordinator_string = server_array.join(" ")
  	
    Chef::Log.info "Coordinator string set to: \"#{coordinator_string}\""

  	return coordinator_string
  end
      
  def self.waitForAppTierTrailblazer(node)
  	query = "role:ziniki-trailblazer"
  	keys = { 'name' => [ 'name' ],
  		     'is_node_ready' => [ 'ziniki', 'is_node_ready'] }
  	servers = waitForNodeQuery(query, keys, node)
  end

  def self.waitForWebTier(node)
  	query = "role:zinikiWebtier"
  	keys = { 'name' => [ 'name' ],
  			 'is_node_ready' => [ 'zinikiWebtier', 'is_node_ready'],
  			 'ip' => [ 'ipaddress' ] }
  	servers = waitForNodeQuery(query, keys, node)
  end

  def self.waitForNodeQuery(search_query, keys_to_retrieve, node)
    sleepTimer = 10
    results = []
    all_nodes_ready = false
    until results.any? && all_nodes_ready do
	  	results = partial_search(:node, "#{search_query} AND chef_environment:#{node.chef_environment}", :keys => keys_to_retrieve)
	  	if results.any?
			if !results.all? { |item| item.has_key?('is_node_ready') }
		      	puts "#{search_query} found. No information available on readiness. Proceeding..."
		      	all_nodes_ready = true
		      	next
		    else
		    	if results.all? { |item| item['is_node_ready'] }
		    		all_nodes_ready = true
		    		next
		    	else
		    		for item in results
		    			if !item['is_node_ready']
		    				puts "Query: #{search_query} found server: #{item.has_key?('name') ? item['name'] : "no name found"}, but not ready."
		    			end
		    		end
		    		puts "Sleeping #{sleepTimer} seconds..."
		    		sleep sleepTimer
		    		next
		      	end	
		    end
		  end	
	  	puts "Unable to find #{search_query}, sleeping #{sleepTimer} seconds..."
	  	sleep sleepTimer
    end
    return results 

  end

end