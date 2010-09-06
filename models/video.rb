class Video
  include DataMapper::Resource

  property :id,  Serial
  property :video_id, String
  property :user, String
  property :title, String, :length => 255
  
  validates_uniqueness_of :video_id
  
  
end

