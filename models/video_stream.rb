require 'yaml'

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
  property :audio_filesize, Integer
  property :audio_filename, Text
  property :track_info, Text
  property :tagged, Boolean
  property :normalized, Boolean
  property :converted, Boolean
  property :directory, String
  
 # validates_uniqueness_of :url
  
  attr_accessor :title, :saved, :path, :video_path, :audio_path, :audio_format, :audio_processed, :last_size
  
  DOWNLOAD_DIR = File.join [File.dirname(__FILE__), "..", "public", "scrape"]
  DEFAULT_AUDIO_FORMAT  = :mp3
  DEFAULT_AUDIO_BITRATE =  "192k"
  DEFAULT_AUDIO_CODEC   = :libmp3lame
  DEFAULT_TRANSCODER = :ffmpeg
  PROGRESS_STORAGE = :file
  NORMALIZE_AUDIO   = true
  PREFERRED_FORMAT = "5"
  
  def self.sanity_check
    self.all.each do |vs|
      vs.rename_dir
    end
  end
  
  def block_log(title, message=nil, options ={})
    log "\n\n"
    log "=" * 50
    log title
    log "=" * 50
    log "\n"
    unless message.nil?
      log message
    end
    log "\n"
  end
  
  def self.delete_all_source
    self.all.each do |vs|
      vs.delete_source
      vs.destroy
    end
  end
  
  def thumbnail
    "http://i1.ytimg.com/vi/#{video_id}/default.jpg"
  end
  
  def audio_data
    self.track_info.nil? ? "" : YAML::load( self.track_info )
  end
  
  def album_thumb
    audio_data["track"]["album"]["image"][0]["#text"] rescue nil
  end
  
  def artist
    audio_data["track"]["artist"]["name"] rescue nil
  end
  
  def artist_url
    audio_data["track"]["artist"]["url"] rescue nil
  end
  
  def track
    audio_data["track"]["name"] rescue nil
  end
  
  def track_url
     audio_data["track"]["url"] rescue nil
  end
  
  def album
     audio_data["track"]["album"]["title"] rescue nil
  end
  
  def album_url
     audio_data["track"]["album"]["url"] rescue nil
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
    fn = fn.gsub(/\s/,"_").gsub(/[^0-9A-Za-z.\- &]/, '').gsub(/[ ]+\./, '.').strip
    return fn
  end
  
  def parent
    Video.first({:video_id => video_id})
  end
  
  def formatt
    Format.first({:id=> format_id})
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
  
  def rename_dir
    log "Checking #{id} / (video id #{video_id})"
    if File.exist?(named_directory) && !File.exist?(stream_directory)
      log "Moving #{named_directory} to  #{stream_directory}"
      #FileUtils.mv named_directory, stream_directory
     # FileUtils.mkdir stream_directory
      FileUtils.cp_r named_directory, stream_directory
      FileUtils.rm_r named_directory
      if !audio_filename.nil?
        audio_dirname = File.dirname(audio_filename)
        audio_basename = File.basename(audio_filename)
        moved_audio      = File.join(stream_directory,audio_basename)
        if audio_dirname == named_directory && File.exist?(moved_audio)
          log "Updating database to reflect changes (Renaming #{audio_filename} to #{moved_audio})"
          self.attributes = { 
            :audio_filename => moved_audio,
            :directory      => stream_directory
          }
          self.save
        end
      end
    end
    log "Changing to #{stream_directory}"
              self.attributes = { 
            :directory      => stream_directory
          }
          self.save
    return stream_directory
  end
  
  def named_directory(options = {})
    options[:location] ||= DOWNLOAD_DIR
    VideoStream.all({:video_id => self.video_id}).map{|vs| vs.audio_filename.nil? ? nil : File.dirname(vs.audio_filename)}.compact.uniq.first || File.expand_path(File.join(options[:location], video_id))
  end
  
  def stream_directory(options = {})
    options[:location] ||= DOWNLOAD_DIR
    File.expand_path(File.join(options[:location], video_id + "_" + format_id))
  end
  
  def default_video_destination(options = {})
    options[:location] ||= DOWNLOAD_DIR
    File.join stream_directory(options), filename
  end
  
  def default_audio_destination(options = {})
    options[:location] ||= DOWNLOAD_DIR
    File.join stream_directory(options), default_audio_filename
  end
  
  def saved?(options = {})
    options[:location] ||=  DOWNLOAD_DIR
    if (@saved && File.exist?(@video_path))
      return true
    elsif File.exist?(default_video_destination(options))
      @video_path = default_video_destination(options)
      return true
    else
      return false
    end
  end
  
  def audio_saved?(options = {})
    (@audio_processed == true && File.exist?(@audio_path)) || 
      (@audio_processed == true && File.exist?(default_audio_destination(options))) ||
      (processed? &&  File.exist?(default_audio_destination(options)))
  end
  
  def processed?
    converted && tagged && (normalize? ? normalized : true)
  end
  
  def progress_file_path
    File.join(stream_directory,"progress.txt")
  end
  
  def conversion_progress_file_path
    File.join(stream_directory,"conversion_progress.txt")
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
  
  
  def set_progress(size, completed = nil)
    #TODO do this right
    @progress_file = File.new(progress_file_path,"a+")
    if update_progress? || completed# To update at data thresholds use update_progress(size, :method => :data)
      percentage = completed ? 100 : (100 * (size.to_f/self.content_length.to_f)).to_s
      @last_size = size
      @last_time = Time.now
      log percentage
      if PROGRESS_STORAGE == :database
        self.attributes = { :progress => percentage }
        self.save
      else
         @progress_file.puts percentage
      end
      @progress_file.close
    end
  end
  
  def get_progress
    File.readlines(progress_file_path).last.to_f rescue 0.0
  end
  
  def download(options = {})
    options[:location] ||= DOWNLOAD_DIR
    @audio_processed = false
    log "Downloading #{filename}"
    @video_destination = default_video_destination(options)
    @tmp_destination   = [ @video_destination, "part" ].join "."
    if saved?(options)
      log "File already exists"
      @video_path = @video_destination
    elsif options[:inline]
      options[:process_audio] = false
      @audio_path     = @audio_destination = (@audio_path || default_audio_destination(options))
      FileUtils.mkdir_p File.dirname(@video_destination)
      command = ffmpeg_inline_conversion_command
      log "Downloading and converting inline \n #{command}"
      system command
    else
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
        File.rename f.path, @video_destination
      rescue => e
        raise "Could not be downloaded to #{@video_destination} \n\n #{e.message} \n\n #{e.backtrace.join("\n")}"
      end
      set_progress(100, true)
      @progress_file.close if @progress_file
    end
    @saved = true
    @video_path = @path = File.expand_path(@video_destination)
    process_audio(options) if options[:process_audio]
    log "File can be viewed at #{@path}"
    return @video_path
  end
  
  
  def normalize?
    NORMALIZE_AUDIO
  end
  
  def audio_bitrate(options = {})
    options[:bitrate] || DEFAULT_AUDIO_BITRATE
  end
  
  def audio_format(options = {})
    (options[:format] || DEFAULT_AUDIO_FORMAT).to_s
  end
  
  def audio_codec(options = {})
    (options[:audio_codec] || DEFAULT_AUDIO_CODEC).to_s
  end
  
  def transcoder(options = {})
    (options[:transcoder] || DEFAULT_TRANSCODER).to_s
  end


  def mplayer_conversion_command(options = {})
    "mplayer  -msglevel all=9  -af volnorm=1 -dumpaudio \"#{@video_path}\" -dumpfile \"#{@audio_destination}\" >> #{conversion_progress_file_path} 2>> #{conversion_progress_file_path}"
  end
  
  def ffmpeg_conversion_command(options = {})
    "ffmpeg -y -i \"#{@video_path}\" -acodec #{audio_codec(options)} -ab #{audio_bitrate(options)} \"#{@audio_destination}\" 2>> #{conversion_progress_file_path}"
  end
  
  def ffmpeg_inline_conversion_command(options = {})
    "curl \"#{url}\" | ffmpeg -y -i -  -acodec #{audio_codec(options)} -ab #{audio_bitrate(options)} \"#{@audio_destination}\" >> #{conversion_progress_file_path} 2>> #{conversion_progress_file_path}"
  end
  
  def normalize_command
    "mplayer -msglevel all=9 -af volnorm=1 \"#{@audio_destination}\" -o \"#{@audio_destination}\" >> #{conversion_progress_file_path} 2>> #{conversion_progress_file_path}"
  end
  
  def estimated_audio_size
    File.size(@video_path) / 3
  end
  
  def converstion_tail(n=5)
    if File.exist? conversion_progress_file_path
      output = IO.popen("tail -n #{n} #{conversion_progress_file_path}").read
      return output
    else
      return ""
    end
  end
  
  def audio_progress
    unless File.exist?(conversion_progress_file_path)
      return 0
    end
    progress_line    = IO.popen("tail -n 1 #{conversion_progress_file_path}").read.split("=")[-3]
    current_size_kb = progress_line.to_s.gsub(/[^0-9]+/,'').to_f
    percent = 1000 * 100 * (current_size_kb/estimated_audio_size.to_f).to_f
    return percent.to_f
  end
  
  def normalize(options= {})
    block_log "Processing with Mplayer"
    if normalize?
      log "Normalizing audio with #{normalize_command}"
      output = IO.popen(normalize_command).read
      self.attributes = { 
        :normalized => true
      }
      self.save
    end
    return output
  end
  
  def extract_audio(options = {})
    log "extracting audio"
    conversion_command = [transcoder(options),"conversion_command"].join("_").to_sym
    command = self.send(conversion_command, {})
    block_log "Processing with FFMpeg"
    log "Converting with\n#{command}"
    output = IO.popen(command).read
    self.attributes = { 
      :converted => true
    }
    self.save
    return output
  end
  
  def process_audio(options = {})
    @audio_processed = false
    download unless saved?
    @audio_destination = default_audio_destination(options)
    if audio_saved?
      @audio_path = @audio_destination
      log "Audio file already exists - #{ @audio_destination}"
      return @audio_path
    end
    extract_audio(options)
    normalize(options)
    if options[:post_process]
      post_process(options) 
    else
      log "No postprocessing - Considering audio process complete"
      @audio_processed = true
    end
    @audio_path = @audio_destination
    return @audio_path
  end
  
  def script_directory
    File.join ROOT, "scripts"
  end
  
  def post_process(options = {})
    log "post processing"
    @audio_path     = (@audio_path || default_audio_destination(options))
    find_info_script   = File.join script_directory, "find_info.rb"
    add_tag_script     = File.join script_directory, "add_tag.rb"
    pp_script = "echo \"#{@audio_path}\" | #{find_info_script} | #{add_tag_script}"
    block_log "Post Processing  - (Looking up possible track info and adding ID3 tags if exists \n #{pp_script}"
    result = IO.popen(pp_script).read
    parsed_track_data = result.split(/[\=]+/)[1]
    track_parse_error = parsed_track_data.match(/error/)
    self.attributes = { 
      :audio_filename => @audio_path,
      :audio_filesize => File.size(@audio_path),
      :track_info =>  track_parse_error ? nil : parsed_track_data,
      :tagged => true
      }
    self.save
    log "Post processing complete"
    @audio_processed = true
    return result
  end
  
end