#!/usr/bin/env ruby



require 'rubygems'
require 'json'
require "yaml"
require 'open-uri'
require 'cgi'
require 'mp3info'


POST_ORGANIZE = true
CHECK_FILES   = false
AUTOTAG      = true
DESTINATION  = "/Users/justin/Music/mp3_rape/"

  
DEFAULT_ARTIST      = "Unknown"
DEFAULT_TRACK_NAME  = "Untitled"
DEFAULT_ALBUM       = ""

output = []



=begin
if CHECK_FILES
  if filename.size < 10
    puts "Filename too short: #{filename}, skipping for now"
    exit
  end

  if File.size(file) < 500
    puts "This file is too small to be anyhting important"
    exit
  end
end

=end

large_img_dir = "http://userserve-ak.last.fm/serve/252/"
small_img_dir = "http://userserve-ak.last.fm/serve/34s/"
artist = track = nil


if STDIN
  
  song_info = YAML::load( STDIN.read )
  
  
  puts "Beginning add_tag.rb - tagging script"
  puts "Song info lookup yielded #{ song_info.to_yaml.size} chars of output"
  
  if song_info[:error]
    puts "Song couldn't be tagged - #{ song_info[:error][:message].to_s}"
    #exit 0
  end
  
  
  # Overkill - being safe while debugging bigger issues
  song_filename = song_info["filename"] || song_info[:filename]
  

  if song_filename.nil?
    puts "No filename passed"
    exit 0
  end
    
  file        = song_filename.gsub("\n",'')
  filename    = File.basename file
  

else

  file        = ARGV[0]


  filename    = File.basename file
  characters  = filename.size#(filename.size.to_f * 0.75).floor

  img_dir = large_img_dir

  query       = filename.to_s.gsub(/\.[a-zA-Z0-9]+$/,'').gsub(/^[0-9 \-_]+/,'').gsub(/[\-\(\)_&]+/,' ').gsub(/[ ]{2,}/,' ')[0..characters]
  search_url  = "http://www.last.fm/search/autocomplete?q=#{CGI.escape(query)}&force=0"
  response    = JSON.parse open(search_url).read

  song_info   = response["response"]["docs"].to_a
  song_info.each do |s|
    s["image"] = File.join(img_dir,s["image"])
  end
  
end



unless song_info.nil?
  
  puts "Song info parsed OK"
  puts "===========\n" + song_info.to_yaml + "\n========="
  
  artist = song_info["track"]["artist"]["name"]  rescue DEFAULT_ARTIST
  track  = song_info["track"]["name"]            rescue DEFAULT_TRACK_NAME
  album  = song_info["track"]["album"]["title"]  rescue DEFAULT_ALBUM
  
  if AUTOTAG
    begin
      Mp3Info.open(file) do |mp3|
        mp3.tag.title  = mp3.tag2.TIT2  = track
        mp3.tag.artist = mp3.tag2.TPE1 = artist
        mp3.tag.comments = mp3.tag2.COMM  = song_info.to_yaml
        mp3.tag.album = mp3.tag2.TALB = album
        album_art = song_info["track"]["album"]["image"][0]["#text"] rescue nil
        if album_art
          art_ext = File.extname(album_art)
          text_encoding = 0
          mime_type = "image/#{art_ext}"
          picture_type = 0
          description = ""
          picture_data = open(album_art).read
          imgd  = [text_encoding, mime_type, picture_type, description, picture_data].pack("c Z* c Z* a*")
          mp3.tag2.APIC = imgd
        end
      end
      output << "RECORD Tagging was a success for #{filename}"
    rescue => e
      output << "An eror prevented #{filename} from being tagged: #{e.message}: #{e.backtrace.join("\n")}"
    end
  end
else
  output << "No song info returned for file:#{file} from url:#{search_url}\n\nReponse:#{response.to_yaml}"
end


puts output.inspect
