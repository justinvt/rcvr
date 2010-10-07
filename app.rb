#!/usr/bin/env ruby

require "rubygems"
require 'dm-core'
require 'dm-migrations'
require 'dm-validations'
require "nokogiri"
require "open-uri"
require 'yajl'
require 'yaml'
require 'sinatra'
require 'uri'
require 'htmlentities'
require 'haml'
require 'json'

require 'logging'

ENVIRONMENT =  :development
ROOT        =  File.dirname(__FILE__)
LOG_PREFIX  =  File.join(ROOT, "log" ,ENVIRONMENT.to_s)
DM_LOG      =  [LOG_PREFIX,"dm","log"].join(".")
APP_LOG     =  [LOG_PREFIX,"app","log"].join(".")
LOG_LEVEL   = :debug



[:config,  :models, :lib, :routes].each do |dir|
  Dir["#{dir.to_s}/*.rb"].each {|file| load file }
end

DataMapper.finalize


#DataMapper.auto_migrate!
DataMapper.auto_upgrade!

if ENVIRONMENT == :development
 # VideoStream.delete_all_source
end


puts "=" * 50
puts "BOOTING APP"
puts "=" * 50

unless ARGV[0].nil?
  set :run, false
  url_or_id = ARGV[0]
  #If no match it's an ID or search query
  unless url_or_id =~ /^(http|www\.youtube\.com|youtube\.com)/
    unless url_or_id =~ Video.pattern
      puts "Searching youtube for #{url_or_id}"
      search = Search.new(url_or_id)
      puts "Found match - " + search.first.video_id
      url_or_id = Search.vid(search.first)
    end
  end
  puts "Retrieving Video information"
  @video_id = YouTube.get_video_id(url_or_id)
  @v = VideoStream.first(:video_id => @video_id, :format_id => "18")
  puts "Retrieving Video information"
  if @v.nil?
    yt = YouTube.new(@video_id, "18")
    yt.retrieve
    @v = VideoStream.first(:video_id => @video_id, :format_id => "18") || VideoStream.first(:video_id => @video_id)
  end
  @v.download
  @v.process_audio
  @v.post_process
end


