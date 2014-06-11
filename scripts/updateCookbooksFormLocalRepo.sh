#!/bin/bash

# source shflags and ansicolor
. scripts/shflags
. scripts/ansicolor

#argument definitions
DEFINE_string		'chef-repo' 	'$CHEF_HOME' 		'path to chef-repo' 			'c'
#DEFINE_integer		'integer' 	'0' 			'integer description' 			'i'
#DEFINE_float		'float' 	'1.5' 			'float description' 			'f'
#DEFINE_boolean		'boolean' 	'false' 		'boolean description' 			'b'

# parse the command-line
FLAGS "$@" || exit 0
eval set -- "${FLAGS_ARGV}"

current_dir=$(pwd)

cd chef/cookbooks

for file in *; do
  echo "updating ${file}"
  cp -r ${CHEF_HOME}/cookbooks/${file}/* ${file}/
done

cd ${current_dir}
