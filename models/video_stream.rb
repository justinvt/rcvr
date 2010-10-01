class VideoStream
  include DataMapper::Resource

  property :id,  Serial
  property :video_id, String
  property :format_id, String
  property :url, Text
  property :signature, Text
  property :mime, String
  property :file_header, Text
  property :params, Text
  property :headers, Text
  property :http_status, String
  property :progress, Integer
  property :content_length, Integer
  property :audio_filename, Text
  
 # validates_uniqueness_of :url
  
  attr_accessor :title, :saved, :path, :video_path, :audio_path, :audio_format, :audio_processed, :last_size
  
  DOWNLOAD_DIR = File.join [File.dirname(__FILE__), "..", "public", "scrape"]
  DEFAULT_AUDIO_FORMAT  = :mp3
  DEFAULT_AUDIO_BITRATE =  "192k"
  DEFAULT_TRANSCODER = :ffmpeg
  PROGRESS_STORAGE = :file
  
  def self.delete_all_source
    self.all.each do |vs|
      vs.delete_source
      vs.destroy
    end
  end
  

  def delete_source
    FileUtils.rm_r stream_directory rescue log "#{stream_directory} Couldn't be deleted"
  end
  
  def sanitize_filename(fn)
    fn = fn.strip
   # NOTE: File.basename doesn't work right with Windows paths on Unix
   # get only the filename, not the whole path
    fn.gsub! /^.*(\\|\/)/, ''

   # Finally, replace all non alphanumeric, underscore 
   # or periods with underscore
   # name.gsub! /[^\w\.\-]/, '_'
   # Basically strip out the non-ascii alphabets too 
   # and replace with x. 
   # You don't want all _ :)
    fn.gsub!(/[^0-9A-Za-z.\- ]/, 'x')
    return fn
  end

  
  
  def parent
    Video.first({:video_id => video_id})
  end
  
  def title
    sanitize_filename(parent.title)
  end
  
  
  def ext
    mime.split(/[^a-zA-Z0-9]+/).last
  end
  
  alias :video_format :ext
  
  def filename
    [ title, video_format.to_s ].join "."
  end
  
  
  def default_audio_filename(format = :mp3)
    @audio_format = format
    [ title, @audio_format.to_s ].join "." 
  end
  
  
  def stream_directory(location = DOWNLOAD_DIR)
     File.expand_path(File.join(location, video_id))
  end
  
  def default_video_destination(location = DOWNLOAD_DIR)
    File.join stream_directory(location), filename
  end
  
  def default_audio_destination(location = DOWNLOAD_DIR)
    File.join stream_directory(location), default_audio_filename
  end
  
  def saved?(location = DOWNLOAD_DIR)
    if (@saved && File.exist?(@video_path))
      return true
    elsif File.exist?(default_video_destination(location))
     @video_path = default_video_destination(location)
     return true
    end
  end
  
  def audio_saved?(location = DOWNLOAD_DIR)
    (@audio_processed && File.exist?(@audio_path)) || File.exist?(default_audio_destination(location))
  end
  
  def progress_file_path
    File.join(stream_directory,"progress.txt")
  end
  
  def update_progress?(size=nil, options ={})
    options[:method] ||= :time
    if options[:method].to_sym == :data
      data_update?(size)
    else
      time_update?
    end
  end
  
   def progress_update_time_threshold
     0.3#milliseconds
  end
  
  def progress_update_data_threshold
     30000 #bits?
  end
  
  def time_update?
    @last_time ||= Time.now
    Time.now - @last_time > progress_update_time_threshold
  end
  
  def data_update?(size)
    (@last_size == 0 || size - @last_size > progress_update_threshold)
  end
  
  
  def set_progress(size)
    #TODO do this right
    if @progress_file
    elsif File.exist?(progress_file_path)
      @progress_file = File.new(progress_file_path,"a+")
    else
      @progress_file = File.new(progress_file_path,"a+")
    end
    if update_progress?# To update at data thresholds use update_progress(size, :method => :data)
      percentage = (100 * (size.to_f/self.content_length.to_f)).to_s
      @last_size = size
      @last_time = Time.now
      if PROGRESS_STORAGE == :file
        @progress_file.puts percentage
      else
        self.attributes = { :progress => percentage }
        self.save
      end
    end
  end
  
  def get_progress
    File.readlines(progress_file_path).last.to_f rescue 0.0
  end
  
  def download(location = DOWNLOAD_DIR)
    log "Downloading #{filename}"
    @video_destination = default_video_destination(location)
    @tmp_destination   = [ @video_destination, "part" ].join "."
    if saved?(location)
      log "File already exists"
      @video_path = @video_destination
      return @video_destination
    end
    log "Attempting to save to #{@video_destination}"
    @last_size = 0
    begin
      FileUtils.mkdir_p File.dirname(@video_destination)
      f = File.new @tmp_destination, "w+"
      f.puts open("#{url}",
        :progress_proc => lambda {|size|
          set_progress(size)
        }).read
      f.close
      @progress_file.close if @progress_file
      File.rename f.path, @video_destination
    rescue => e
      raise "Could not be downloaded to #{@video_destination} \n\n #{e.message} \n\n #{e.backtrace.join("\n")}"
    end
    @saved = true
    @video_path = @path = File.expand_path(@video_destination)
    log "File can be viewed at #{@path}"
    return @video_path
  end
  


  def mplayer_conversion_command(options = {})
    bitrate = options[:bitrate] || DEFAULT_AUDIO_BITRATE
    format  = options[:format] || DEFAULT_AUDIO_FORMAT
    "mplayer -af volnorm=1 -dumpaudio \"#{@video_path}\" -dumpfile \"#{@audio_destination}\""
  end
  
  def ffmpeg_conversion_command(options = {})
    bitrate = options[:bitrate] || DEFAULT_AUDIO_BITRATE
    format  = options[:format] || DEFAULT_AUDIO_FORMAT
    "ffmpeg -y -i \"#{@video_path}\"  -acodec libmp3lame  -ab #{bitrate} \"#{@audio_destination}\""
  end
  
  def audio
  end
  
  def audio_progress
    File.size?( default_audio_filename).to_i
  end
  
  
  
  def process_audio(options = {})
    location   = options[:location]   || DOWNLOAD_DIR
    format     = options[:format]     || DEFAULT_AUDIO_FORMAT
    transcoder = options[:transcoder] || DEFAULT_TRANSCODER
    download unless saved?
    @audio_destination = default_audio_destination(location)
    if audio_saved?
      log "Audio file already exists"
      @audio_path = @audio_destination
      return @audio_path
    end
    conversion_command = [transcoder.to_s,"conversion_command"].join("_").to_sym
    conversion_options = {}
    command = self.send(conversion_command, conversion_options)
    log "Converting with #{command}"
    system command
    @audio_path = @audio_destination
    @audio_processed = true
    return @audio_path
  end
  
  def post_process
    file_location = (@audio_path || default_audio_destination)
    info_script = File.join ROOT, "scripts", "find_info.rb"
    tag_script     = File.join ROOT, "scripts", "add_tag.rb"
    puts "Renamin #{file_location}"
    #result = IO.popen("echo \"#{file_location}\" | #{info_script} | #{tag_script}").read
    result = IO.popen("echo \"#{file_location}\"").read
    puts "new filename #{result}"
    @audio_path = file_location
    self.attributes = { :audio_filename =>file_location }
    self.save
    return result
  end
  
end