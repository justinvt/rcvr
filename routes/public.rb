

  def get_stream
    @video_id = YouTube.get_video_id(params[:video_id])
    @v = VideoStream.first(:video_id => @video_id, :format_id => "18")
    if @v.nil?
      yt = YouTube.new(@video_id, "18")
      yt.retrieve
      @v = VideoStream.first(:video_id => @video_id, :format_id => "18") || VideoStream.first(:video_id => @video_id)
    end
   # @v.download
    return @v
  end
  
  get '/' do
    session[:recents] ||= []
    @current_action = "home"
    haml :home, :layout => :"templates/main"
  end
  
  get '/youtube/video/:video_id' do
    @v = get_stream
    @v.download
    send_file @v.video_path,
      :type => @v.mime,
      :disposition => 'attachment'
  end
  
  get '/youtube/reprocess/:video_id' do
    @spock = Spork.spork(:logger => @log) do
      @v = get_stream
      @v.process_audio
      @v.post_process
    end
  end
  
  get '/youtube/redownload/:video_id' do
    @spock = Spork.spork(:logger => @log) do
      @v = get_stream
      @v.download
      @v.process_audio
      @v.post_process
    end
  end
  
  get '/youtube/retag/:video_id' do
  #  @spock = Spork.spork(:logger => @log) do
      @v = get_stream
      if @v.track_info.nil?
        @v.post_process
      end
      content_type 'text/javascript', :charset => 'utf-8'
      @v.audio_data.to_json
   # end
  end
  
  get '/youtube/audio' do
    session[:recents] << YouTube.get_video_id(params[:video_id])
    @spock = Spork.spork(:logger => @log) do
      @v = get_stream
      @v.download
      @v.process_audio
      @v.post_process
    end
    redirect "/downloading/#{ YouTube.get_video_id(params[:video_id])}", 302
   # send_file @v.audio_path,
  #    :type => 'audio/mpeg',
  #    :disposition => 'attachment'
  end
  
  #Landing page after form submission that displays progress
  get '/downloading/:video_id' do
    @v = get_stream
  #  @spock = Spork.spork(:logger => @log) do
  #    @v.download
  #  end
    haml :downloading, :layout => :"templates/main"
  end
  
  # For ajax calls to get file progress
  get '/progress/:video_id' do
    v = get_stream
    content_type 'text/javascript', :charset => 'utf-8'
    {
      :video_id => v.video_id,
      :thumb    => v.thumbnail,
      :url => v.url, 
      :size => v.content_length, 
      :progress => ("%3.1f" % v.get_progress).to_f, 
      :audio_progress => v.audio_progress.to_i, 
      :audio_filename => v.audio_filename.to_s,
      :ext            => v.ext,
      :audio_data     => v.audio_data.to_json
    }.to_json
  end
  

  
  get '/tag/:video_id' do
    @v = get_stream
    @v.post_process
    puts "no this"
    send_file @v.audio_path,
      :type => 'audio/mpeg',
      :disposition => 'attachment'
  end
  
