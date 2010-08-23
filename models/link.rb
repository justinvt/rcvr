class Link
  include DataMapper::Resource

  property :id,  Serial
  property :domain, String
  property :url, String, :length => 255
  property :comment_id, String
  
  belongs_to :comment, 'Comment',
   :parent_key => [:name],
   :child_key  => [:comment_id]
   
  def self.youtube
    all(:url.like => '%youtube.com%')
  end


  
end