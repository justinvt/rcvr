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
  property :post_id, Integer, :default => 4
  
  has n, :links
    
  belongs_to :post, 'Post',
   :parent_key => [:name],
   :child_key  => [:link_id]
   
  def html
    coder = HTMLEntities.new
    coder.decode(body_html)
  end
   
  def collect_links
    doc = Nokogiri::HTML(html)
    links = doc.css("a").map{|a| URI.escape(a["href"])}
    links.each{|url| 
      parsed_url = URI.parse( url )
      Link.create(
        :url => url,
        :domain =>  parsed_url.host,
        :comment_id => name
      ) rescue false
    }
  end
    
  def self.collect_links
    all.each do |c|
      c.collect_links
    end
  end

  
end