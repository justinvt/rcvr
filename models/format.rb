class Format
  include DataMapper::Resource

  property :id, Serial
  property :itag, String
  property :host_id, Integer
  property :mime, String
  property :extension, String
  
  validates_uniqueness_of :itag
  
  def calc_ext
    mime.split(/[^a-z]+/).last
  end



end

