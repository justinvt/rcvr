require "rubygems"
require 'dm-core'
require "nokogiri"
require "open-uri"
require 'yajl'
require 'yaml'

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, 'mysql://root@localhost/metareddit?socket=/tmp/mysql.sock')

Dir["models/*.rb"].each {|file| load file }

DataMapper.finalize

require 'dm-migrations'

#DataMapper.auto_migrate!
DataMapper.auto_upgrade!




#Page.scrape_all
#Comment.collect_links
Link.generate_index
#TODO -  boot
