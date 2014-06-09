# Logic for determining the default number of FDB processes
# Using the following constraints:
# 	 1. Have at least 4 gB of RAM for each process
# 	 2. Always run at least one process
# 	 3. Never run more processes than discrete CPUs
default['foundationdb']['process_count'] = [node[:cpu][:total], [(node[:memory][:total].to_i / 1024 / 1024) / 4, 1].max].min 