#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require "yaml"
require 'yajl'
require 'open-uri'
require 'cgi'
require 'mp3info'
require 'lastfm'

 
 API_KEY = api_key = "0e679bdb647b363cce3d2c71f50451ce"
 api_secret = "a187bc7fecacec015a1ad8996f795bc7"
 
 def get_artist_info(artist)
   resp = open("http://ws.audioscrobbler.com/2.0/?format=json&method=artist.getinfo&artist=#{artist}&api_key=#{API_KEY}")
   resp
  end
  
  if STDIN
    filename = STDIN.read
    parsed_name = File.basename(filename).split(".")[0..-2].join("").split(/[_\-]+/).map(&:strip)
    parts = [parsed_name[0],parsed_name[1..-1].join(" ")]
  else
    parts = ARGV
    filename = nil
  end

 
 
 lastfm = Lastfm.new(api_key, api_secret)
 
 if parts.size == 1

 
   artist_json = get_artist_info(parts[0])
   response = Yajl::Parser.new.parse(artist_json)
   response["filename"] = filename
   puts response.to_yaml
   
 elsif parts.size == 2

   track_request = Lastfm::Track.new(lastfm)
 
   response = track_request.get_info(parts[0],parts[1]).instance_variable_get("@parsed_body")
   response["filename"] = filename
   puts response.to_yaml
   

 end

