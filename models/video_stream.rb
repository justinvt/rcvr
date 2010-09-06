class VideoStream
  include DataMapper::Resource

  property :id,  Serial
  property :video_id, String
  property :format_id, String
  property :url, Text
  property :signature, Text
  property :mime, String
  property :file_header, Text
  
 # validates_uniqueness_of :url
  
  attr_accessor :title, :saved, :path, :video_path, :audio_path
  
  DOWNLOAD_DIR = File.join [File.dirname(__FILE__), "..", "public"]
  
  def title=(tit)
    @title = tit
  end
  
  
  def ext
    mime.split(/[^a-zA-Z0-9]+/).last
  end

  def download(title = @title, location = DOWNLOAD_DIR)
    filename = title + "." + ext
    log "Downloading #{filename}"
   # if saved?
   #   raise "A File with the same filesize exists at #{@path}"
  #  end
    @destination = File.expand_path(File.join(location, filename))
    @tmp_dest    = @destination + ".part"
    log "Attempting to save to #{@destination}"
    begin
      FileUtils.mkdir_p File.dirname(@destination)
      f = File.open(@tmp_dest, "w+")
      f.puts open(url).read
      f.close
      File.rename(File.expand_path(f.path), @destination)
    rescue => e
      raise "Could not be downloaded to #{@destination} \n\n #{e.message} \n\n #{e.backtrace.join("\n")}"
    end
    @saved = true
    @video_path = @path = File.expand_path(@destination)
    log "File can be viewed at #{@path}"
    return @path
  end
  
  def default_audio_path
    filename = (@title + "." + "mp3").gsub(/[ ]+/,"_")
    File.expand_path(File.join(DOWNLOAD_DIR, filename))
  end
  
  def process_audio
    @audio_path = default_audio_path
    #ffmpeg_command =  "ffmpeg -i #{file} -ab 192 -ar 44100 #{result}"
    #old_ext = File.extname(file)
    mplayer_command = "mplayer -af volnorm=1 -dumpaudio \"#{@video_path}\" -dumpfile \"#{@audio_path}\""
    ffmpeg_command = "ffmpeg -i \"#{@video_path}\" -f mp3 \"#{@audio_path}\""
    system ffmpeg_command
   # until op.closed?
    return @audio_path
   # end
    #FileUtils.rm file
    #return result
  end
  
end