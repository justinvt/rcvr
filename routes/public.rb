

  
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
    @spock = Spork.spork(:logger => @log) do
      @v.process_audio
      @v.post_process
    end
    redirect "/downloading/#{@video_id}", 302

   # send_file @v.audio_path,
  #    :type => 'audio/mpeg',
  #    :disposition => 'attachment'
  end
  
  get '/progress/:video_id' do
    v = get_stream
    content_type 'text/javascript', :charset => 'utf-8'
    {:video_id => v.video_id, :size => v.content_length, :progress => v.get_progress.to_i, :audio_progress => v.audio_progress.to_i, :audio_filename => v.audio_filename.to_s}.to_json
  end
  
  get '/downloading/:video_id' do
    @v = get_stream
    haml :downloading, :layout => :"templates/main"
  end
  
  get '/tag/:video_id' do
    @v = get_stream
    @v.post_process
    puts "no this"
    send_file @v.audio_path,
      :type => 'audio/mpeg',
      :disposition => 'attachment'
  end
  
