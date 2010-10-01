class Video
  include DataMapper::Resource

  property :id,  Serial
  property :video_id, String
  property :user, String
  property :title, String, :length => 255
  
  validates_uniqueness_of :video_id
  
  def process_audio
    @v = VideoStream.first(:video_id => video_id, :format_id => "18")
    @v.process_audio
  end
  
  
end

