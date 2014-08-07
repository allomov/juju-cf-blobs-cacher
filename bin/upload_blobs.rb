#!/usr/bin/env ruby

$LOAD_PATH.unshift('lib')

require 'helpers'
require 'yaml'
require 'json'
require 'httparty'
require 'fog'

include Helpers

options_parser.parse!
# load_config

p "Reading config from #{options[:config]}..."
config = YAML.load_file(options[:config])

p "Fetching S3 config from #{config[:url]}"
blobstore_structure = HTTParty.get(config[:url]).parsed_response

p "Connecting to OpenStack as #{config['swift']['user']} to #{config['swift']['url']}..."
swift = Fog::Storage.new({
  :provider            => 'OpenStack',
  :openstack_username  => config['swift']['user'],
  :openstack_api_key   => config['swift']['password'],
  :openstack_auth_url  => config['swift']['url'],
  :openstack_tenant    => config['swift']['tenant']
})


# container = config['swift']['container']

blobstore_structure.keys.each do |c|
  unless swift.container_exists?(c)
    p "Creating container #{c}..."
    swift.create_container(c)
  end
end

traverse(blobstore_structure) do |value, parents, leaf|

  current_folder = swift
  parents.each { |p| current_folder = current_folder.directories.get(p) }

  if leaf
    package_path = [parents, value].flatten.join('/')
    package_url = [config[:artifacts_url], package_path].join('/')
    file_name = File.join config[:directory], value
    p "Fetching #{value} from #{package_url} to #{file_name}"
    File.open(file_name, "wb") do |f|
      f.write HTTParty.get(package_url).parsed_response
    end
    p "Wrining #{value} to Swift"
    current_folder.files.create(key: value, body: File.open(file_name))
  else
    current_folder.directories.create(key: value)
  end
end








