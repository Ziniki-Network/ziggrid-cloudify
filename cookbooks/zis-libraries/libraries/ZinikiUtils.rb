module ZinikiUtils
  
  def addNodeNameToLogstashAgent()
    add_name_filter = {"mutate"=>{"add_field"=>[ "node_name", "#{node.name}" ]}}

    if !node['logstash']['agent']['filters'].include?(add_name_filter)
      Chef::Log.info "adding node_name filter to logstash filter list"
      current_filters = Array.new(node['logstash']['agent']['filters'])
      current_filters << add_name_filter

      Chef::Log.debug "Updated filters:"
      current_filters.each do |filter|
        Chef::Log.debug "---filter: #{filter}"
      end

      node.override['logstash']['agent']['filters'] = current_filters
      node.save
    else
      Chef::Log.info "node_name filter already present in logstash filter list"
    end
   
  end

end