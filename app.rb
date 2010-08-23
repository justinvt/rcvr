require "rubygems"
require 'dm-core'
require "nokogiri"
require "open-uri"
require 'yajl'
require 'yaml'
require 'sinatra'


DataMapper::Logger.new($stdout, :warn)
DataMapper.setup(:default, 'mysql://root@localhost/metareddit?socket=/tmp/mysql.sock')

[:models, :lib, :routes].each do |dir|
  Dir["#{dir.to_s}/*.rb"].each {|file| load file }
end

DataMapper.finalize

require 'dm-migrations'

#DataMapper.auto_migrate!
DataMapper.auto_upgrade!




#Page.scrape_all
#Comment.collect_links
#Link.generate_index
#TODO -  boot
