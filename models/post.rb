class Post
  include DataMapper::Resource

  property :id, Serial
  property :after, String
  property :modhash, String
  property :before, String
  property :kind, String
  property :name, String
  property :permalink, String, :length => 255 
  property :over_18, Boolean
  property :is_self, Boolean
  property :ups, Integer
  property :downs, Integer
  property :num_comments, Integer
  property :title, String, :length => 255 
  property :author, String
  property :thumbnail, String, :length => 255 
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
  property :json, Text
  property :page_id, Integer
  
  has n, :comments, 
    :child_key  => [:link_id], 
    :parent_key => [:name]
  
  
  attr_accessor :json_object
  
  
  def self.scrape(url, source_page)
    post = Post.new(:permalink => url)
    puts "scraping #{post.json_url}"
    begin
      post.json_object = Yajl::Parser.new.parse(open(post.json_url))
      post_data = post.json_object[0]["data"]["children"][0]["data"]
      post.author = post_data["author"]
      post.title = post_data["title"]
      post.name  = post_data["name"]
      #post.page_id = source_page.id
      post.thumbnail = post_data["thumbnail"]
      post.url = post_data["url"]
      post.save
      parse_comments(post.json_object[1]["data"]["children"])
    rescue => e
      puts "\n\n Post Data: " + post_data.inspect + "\n\n"
      puts "skipping for error #{e.backtrace.join("\n")}"
    end
    return post
  end
  
  def self.parse_comments(objs)
    puts "Parsing comments"
    objs.each do |c|
      cdata = c["data"]
      comment = Comment.create(
        :name => c["data"]["name"],
        :body_html => c["data"]["body_html"],
        :body => c["data"]["body"],
        :link_id => c["data"]["link_id"],
        :parent_id => c["data"]["parent_id"],
        :author => c["data"]["author"]
      )
      Post.parse_comments(c["data"]["replies"]["data"]["children"]) rescue next
    end
  end
  
  def json_url
    permalink.gsub(/\/$/,".json")
  end
  


end

