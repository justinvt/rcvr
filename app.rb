require "rubygems"
require 'dm-core'
require 'dm-migrations'
require "nokogiri"
require "open-uri"
require 'yajl'
require 'yaml'
require 'sinatra'
require 'uri'
require 'htmlentities'
require 'haml'




DataMapper::Logger.new("dev.log", :debug)
DataMapper.setup(:default, 'mysql://root@localhost/metareddit?socket=/tmp/mysql.sock')

[:config, :lib, :models, :routes].each do |dir|
  Dir["#{dir.to_s}/*.rb"].each {|file| load file }
end

DataMapper.finalize


#DataMapper.auto_migrate!
#DataMapper.auto_upgrade!




#Page.scrape_all
#page = Page.create(:url => "http://www.reddit.com")
#page.scrape
#Comment.collect_links
#Link.generate_index
#TODO -  boot
