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
  property :json, Text
  
  attr_accessor :json_object
  
  
  def self.scrape(url)
    post = Post.new(:url => url)
    puts "scraping #{post.json_url}"
    begin
      post.json_object = Yajl::Parser.new.parse(open(post.json_url))
      post.json = post.json_object.inspect
      post.save
    rescue
      puts "skipping for error"
    end
    parse_comments(post.json_object[1]["data"]["children"])
    return post
  end
  
  def self.parse_comments(objs)
    puts "\n\nParsing:\n\n" + objs.inspect + "\n\n"
    objs.each do |c|

      puts "\n\n" + c["data"].inspect + "\n\n"
      begin
      comment = Comment.new(
        :name => c["data"]["name"],
        :body_html => c["data"]["body_html"],
        :body => c["data"]["body"],
        :link_id => c["data"]["link_id"],
        :parent_id => c["data"]["parent_id"],
        :id => c["data"]["id"],
        :author => c["data"]["author"]
      )
      comment.save
    rescue
      puts "Skipping"
    end
      if c["data"]["replies"] == ""
        next
      else
        Post.parse_comments(c["data"]["replies"]["data"]["children"]) rescue next
      end
    end
  end
  
  def json_url
    url.gsub(/\/$/,".json")
  end
  


end

