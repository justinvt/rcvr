class Page
  include DataMapper::Resource

  property :id, Serial
  property :after, String
  property :modhash, String
  property :before, String
  property :kind, String
  property :name, String
  property :permalink, String
  property :over_18, Boolean
  property :is_self, Boolean
  property :ups, Integer
  property :downs, Integer
  property :num_comments, Integer
  property :title, String
  property :author, String
  property :thumbnail, String
  property :created, DateTime
  property :created_utc, DateTime
  property :url, String, :length => 255 
  property :domain, String
  property :selftext, Text
  property :selftext_html, Text
  property :media, String
  property :media_embed, Text
  property :clicked, Boolean
  property :subreddit, String
  property :subreddit_id, String
  property :score, Integer
  property :hidden, Boolean
  property :likes, String
  
  @@domain = "reddit.com"
  
  
  cattr_accessor :domain,
                 :doc,
                 :posts
  
  def doc
    Nokogiri::HTML(open( self.url ))
  end
  
  def posts
    doc.css("div.entry a.comments")
  end
  
  def scrape
    posts.each do |link|
      url = link["href"]
      Post.scrape(url, self)
    end
  end

end

