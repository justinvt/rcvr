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
  
  def self.pattern
    files = all.map(&:video_id)
    characters = files.join.split(/./).uniq
    lengths = files.map{|f| f.length }
    min_length = lengths.min
    max_length = lengths.max
    set_length = lengths.uniq.size == 1
    ({:characters => characters, :lengths => lengths, :set_length => set_length})
    regex = '[a-zA-Z0-9\-_]{'+"#{min_length},#{max_length}" + '}'
    log "REGEX - #{regex}"
    Regexp.new(regex)
  end
  
  def thumbnail
    "http://i1.ytimg.com/vi/#{video_id}/default.jpg"
  end
  
  
end

