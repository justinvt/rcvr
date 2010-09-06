
  
  get '/' do
    haml :home, :layout => :"templates/main"
  end
  
  get '/youtube/*' do
    url_or_id = params[:video_id] || params[:splat][0]
    video_id = YouTube.get_video_id(url_or_id)
    puts video_id
   
   # YouTube::FORMATS.each do |f|
      yt = YouTube.new(video_id, "18")
      yt.retrieve
      yt.streams
   # end
    @v = VideoStream.first(:video_id => video_id, :format_id => "18")
    if @v.nil?
       @v = VideoStream.all(:video_id => video_id).first
    end
    @v.title = yt.title
    @v.download
    @v.process_audio

    #puts @domain
    
   # puts @v.default_audio_path
    send_file @v.default_audio_path,
      :type => 'audio/mpeg',
      :disposition => 'attachment'
    #haml :video, :layout => :"templates/main"
  end
  
