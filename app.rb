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
LOG_PREFIX  =  File.join(ROOT, ENVIRONMENT.to_s)
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
  VideoStream.delete_all_source
end


