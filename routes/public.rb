
  def process_query(search)
    @search_term = search
    if @search_term  =~ Video.pattern
      @video_id = YouTube.get_video_id(@search_term)
    else
      log "Searching youtube for #{@search_term}"
      search = Search.new(@search_term)
      log "Found match - " + search.first.video_id
      @video_id = Search.vid(search.first)
    end
    return @video_id
  end

  def get_stream
    @video_id ||= params[:video_id]
    @format = VideoStream::PREFERRED_FORMAT
    @v = VideoStream.first(:video_id => @video_id, :format_id => @format)
    if @v.nil?
      yt = YouTube.new(@video_id, @format)
      yt.retrieve
      @v = VideoStream.first(:video_id => @video_id, :format_id => @format) || VideoStream.first(:video_id => @video_id)
    end
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
    @reprocess = fork do
      @v = get_stream
      @v.process_audio(:post_process => true )
    end
  end
  
  get '/youtube/redownload/:video_id' do
    @download = fork do
      @v = get_stream
      @v.download(:post_process => true, :process_audio => true)
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
    @video_id = params[:video_id] || process_query(params[:search_query])
    session[:recents] << @video_id
    @handle_dl = fork do
      @v = get_stream
      @v.download
      @v.process_audio(:post_process => true )
    end
    redirect "/downloading/#{@video_id}", 302
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
      :audio_progress =>  v.converstion_tail, 
      :audio_filename => v.audio_saved? ? v.audio_filename.to_s : "",
      :ext            => v.ext
      #:audio_data     => v.audio_data.to_json
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
  
