#!/usr/bin/env ruby

$LOAD_PATH.unshift('lib')

require 'optparse'
require 'helpers'
require 'yaml'

include Helpers

options_parser.parse!
# load_config

p "Reading config from #{options[:config]}..."
config = YAML.load_file(options[:config])

p "Fetching S3 config from "


p "Connecting to Swift as #{config['swift']['user']} to #{config['swift']['url']}..."
swift = Openstack::Swift::Client.new(
  config['swift']['url'],
  config['swift']['user'],
  config['swift']['password']
)

swift.upload("choosed_container", "/path/of/your/file")

