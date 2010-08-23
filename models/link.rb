class Link
  include DataMapper::Resource

  property :id,  Serial
  property :url, String, :length => 255
  property :comment_id, String
  
  
  def self.generate_index
    f = File.new("public/index.html","w+")
    f.puts "<html><HEAD><title>metareddit</title></HEAD><body>"
    self.all.map{|l| l.url}.uniq.each do |l|
      f.puts "<div><a href=#{l}>#{l}</a></div>"
    end
    f.puts "</body></html>"
    f.close
  end


  
end