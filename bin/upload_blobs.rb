#!/usr/bin/env ruby

$LOAD_PATH.unshift('lib')

require 'helpers'
require 'yaml'
require 'json'
require 'httparty'
require 'fog'

include Helpers

options_parser.parse!

load_config!

load_blobstore_structure!

connect_to_swift!

blobstore_structure.keys.each do |container_name|
  swift.directories.create(key: container_name)
end


traverse(blobstore_structure) do |value, parents, is_package|
  
  puts [value, parents, is_package].inspect
  
  if is_package

    file_name = File.join(options[:directory], value)
    package_path = [parents, value].flatten.join('/')
    download_package(value, package_path, file_name)

    p "Wrining #{value} to Swift to #{package_path} pseudo-folder."
    container    = swift.directories.create(key: parents[0])
    package_path = [parents[1, -1], value].flatten.join('/')
    container.files.create(key: package_path, body: File.open(file_name))
  end

  puts "-------------------"
end








