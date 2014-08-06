require 'optparse'

module Helpers
  attr_accessor :options

  def options_parser
    @options ||= {}

    OptionParser.new do |opts|
      opts.banner = "Cache Canonical CF Charm binaries to Swift.\n" + 
                    "Usage: ./bin/upload_blobs.rb [options]"
    
      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        @options[:verbose] = v
      end
    
      opts.on("-c", "--config", "Config file (cofnfig/config.yml by default)") do |v|
        @options[:config] = v || 'cofnfig/config.yml'
      end
    
      opts.on("-h", "--help", "Config file") do |v|
      	puts opts.summarize(STDOUT)
      end
    
      opts.on("-d", "--direcotory", "Directory that will be used to download blobs") do |v|
        @options[:direcotory] = v || 'tmp'
      end

      opts.on("-u", "--url", "URL to blob storage to cache") do |v|
        @options[:storage] = v || 'http://cf-compiled-packages.s3-website-us-east-1.amazonaws.com'
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
        traverse(v, k, false, &blk) 
      end
    when Array
      obj.each {|v| traverse(v, parents, true, &blk) }
    else
      blk.call(obj, parent, true)
    end
  end

end