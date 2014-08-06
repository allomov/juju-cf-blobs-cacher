#!/usr/bin/env ruby

$LOAD_PATH.unshift('lib')

require 'helpers'
require 'yaml'
require 'json'
require 'httparty'

include Helpers

options_parser.parse!
# load_config

p "Reading config from #{options[:config]}..."
config = YAML.load_file(options[:config])

p "Fetching S3 config from #{config[:url]}"
blobstore_structure = HTTParty.get(config[:url]).parsed_response

p "Connecting to Swift as #{config['swift']['user']} to #{config['swift']['url']}..."
swift = Openstack::Swift::Client.new(
  config['swift']['url'],
  config['swift']['user'],
  config['swift']['password']
)

traverse(blobstore_structure) do |value, parents, leaf|
  if leaf
    package_url = [config[:url], parents, value].flatten.join('/')
    file_name = File.join config[:directory], value
    p "Fetching #{value} from #{package_url} to #{file_name}"
    File.open(file_name, "wb") do |f|
      f.write HTTParty.get(package_url).parsed_response
    end
    swift.upload("container", file_name)
  end
end








