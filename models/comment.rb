class Comment
  include DataMapper::Resource
  


  property :id,  Serial
  property :kind, String
  property :author, String
  property :link_id, String
  property :parent_id, String
  property :subreddit_id, String
  property :name, String
  property :likes, Integer
  property :url, String, :length => 255 
  property :permalink, String, :length => 255 
  property :created, DateTime
  property :created_utc, DateTime
  property :ups, Integer
  property :downs, Integer
  property :body, Text, :lazy => false
  property :body_html, Text, :lazy => false
  

  
  belongs_to :post, 'Post',
   :parent_key => [:name],
   :child_key  => [:link_id]
  
  has n, :links
    
  def self.collect_links
    comms = all
    comms.each do |c|
      links = c.body_html.to_s.match(/href=\"[^\s]+\"/).to_a
      links.each{|l| 
        Link.create(:url => l.gsub(/href=|\"/,''), :comment_id => c.name) rescue false
        }
    end
  end

  
end