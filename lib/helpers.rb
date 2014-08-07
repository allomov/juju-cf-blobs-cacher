require 'optparse'

module Helpers
  attr_accessor :options, :config, :blobstore_structure, :swift

  def options_parser
    @options ||= { config: 'config/config.yml',
                   directory: './tmp',
                   storage: nil }

    OptionParser.new do |opts|
      opts.banner = "Cache Canonical CF Charm binaries to Swift.\n" + 
                    "Usage: ./bin/upload_blobs.rb [options]"
    
      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        @options[:verbose] = v
      end
    
      opts.on("-c", "--config CONFIG", "Config file (config/config.yml by default)") do |c|
        @options[:config] = c
      end
    
      opts.on("-h", "--help", "Print help") do
      	puts opts
      end
    
      opts.on("-d", "--directory DIR", "Directory that will be used to download blobs") do |dir|
        @options[:directory] = dir
      end

      opts.on("-u", "--url URL", "URL to blob storage to cache") do |url|
        @options[:storage] = url
      end
    
    end
  end


  def p(text, force = false)
  	puts(text) if force || @options[:verbose]
  end

  def traverse(obj, parents=[], leaf=false, &blk)
    case obj
    when Hash
      obj.each do |k, v| 
        blk.call(k, parents, false)
        # Pass hash key as parent
        traverse(v, parents.push(k), false, &blk) 
      end
    when Array
      obj.each {|v| traverse(v, parents, true, &blk) }
    else
      blk.call(obj, parents, true)
    end
  end

  def load_config!
    p "Reading config from #{options[:config]}..."
    @config ||= YAML.load_file(options[:config])    
  end

  def artifacts_url
    options[:storage] || config['artifacts_url']
  end

  def load_blobstore_structure!
    url = artifacts_url
    p "Fetching S3 config from #{url}"
    @blobstore_structure ||= HTTParty.get(url).parsed_response
  end

  def connect_to_swift!
    p "Connecting to OpenStack as #{config['swift']['user']} to #{config['swift']['url']}..."
    @swift ||= Fog::Storage.new({
      :provider            => 'OpenStack',
      :openstack_username  => config['swift']['user'],
      :openstack_api_key   => config['swift']['password'],
      :openstack_auth_url  => config['swift']['url'],
      :openstack_tenant    => config['swift']['tenant']
    })
  end

  def download_package(package_name, package_path, file_name)
    package_url = [artifacts_url, package_path].join('/')
    p "Fetching #{package_name} from #{package_url} to #{file_name}"
    File.open(file_name, "wb") do |f|
      f.write HTTParty.get(package_url).parsed_response
    end    
  end

end