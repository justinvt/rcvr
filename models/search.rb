require 'youtube_g'


class Search
  
  
  #cattr_accessor :client
  attr_accessor :videos, :query
  
  @@client  = YouTubeG::Client.new



  def initialize(query)
    @query = query
    @videos = @@client.videos_by(:query => query)
  end
  
  def first
    @videos.videos.first
  end
  
  def self.vid(video)
    video.video_id.split("/").last
    
  end


end

