def get_stream
  url_or_id = params[:video_id]
  @video_id = YouTube.get_video_id(url_or_id)
  v = VideoStream.first(:video_id => @video_id, :format_id => "18")
  if v.nil?
    yt = YouTube.new(@video_id, "18")
    yt.retrieve
    v = VideoStream.first(:video_id => @video_id, :format_id => "18") || VideoStream.first(:video_id => @video_id)
  end
  return v
end
  
  get '/' do
    haml :home, :layout => :"templates/main"
  end
  
  get '/youtube/video/:video_id' do
    @v = get_stream
    @v.download
    send_file @v.video_path,
      :type => @v.mime,
      :disposition => 'attachment'
  end
  
  get '/youtube/audio/:video_id' do
    @v = get_stream
    @p1 = Process.fork{
      @v.process_audio
      @v.post_process
    }
    redirect "/progress/#{@video_id}", 302

   # send_file @v.audio_path,
  #    :type => 'audio/mpeg',
  #    :disposition => 'attachment'
  end
  
  get '/tag/:video_id' do
    @v = get_stream
    @v.post_process
    puts "no this"
    send_file @v.audio_path,
      :type => 'audio/mpeg',
      :disposition => 'attachment'
  end
  
