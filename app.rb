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




DataMapper::Logger.new("dev.log", :debug)
DataMapper.setup(:default, 'mysql://root@localhost/youtube?socket=/tmp/mysql.sock')
DataMapper::Model.raise_on_save_failure = true

[:config,  :models, :lib, :routes].each do |dir|
  Dir["#{dir.to_s}/*.rb"].each {|file| load file }
end

DataMapper.finalize

mime_type :flv, 'video/x-flv'
mime_type :mp4, 'video/mp4'



#DataMapper.auto_migrate!
DataMapper.auto_upgrade!





#page = Page.create(:url => "http://www.reddit.com")
#page.scrape
#Comment.collect_links
#Link.generate_index
#TODO -  boot
