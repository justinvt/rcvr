class Link
  include DataMapper::Resource

  property :id,  Serial
  property :domain, String
  property :url, String, :length => 255
  property :thumbnail, String, :length => 255
  property :comment_id, String
  
  belongs_to :comment, 'Comment',
   :parent_key => [:name],
   :child_key  => [:comment_id]
   
  def self.from(domain)
    all(:domain.like => "%#{domain}%")
  end
   
  def self.youtube
    all(:url.like => '%youtube.com%')
  end
  
  def foreign_id
    case domain
       when /youtube/   : url.split(/v=/)[-1].match(/^[a-zA-Z0-9\-_]+/).to_s
       when /wikipedia/ : url.split(/\//)[-1].to_s
       when /imgur/     : (file = url.split(/\//)[-1];parts = file.split(".");parts[0]).to_s
    end
  end
  
  def ext
    url.split(".")[-1]
  end
  
  def thumbnail
    calculated_thumb
  end
  
  
  def calculated_thumb
    case domain
      when /youtube/ : "http://img.youtube.com/vi/#{foreign_id}/2.jpg"
      when /imgur/ : "http://i.imgur.com/#{foreign_id}s.#{ext}"
    end
  end


  
end