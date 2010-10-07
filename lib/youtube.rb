require 'rubygems'
require 'yajl'
require 'open-uri'
require 'nokogiri'
require 'uri'
require 'net/http'
require 'cgi'
require 'rack'



DEFAULT_DOWNLOAD_LOCATION = "/Volumes/justin/youtube"
YT_LOG_LEVEL = "WARN"


def log(entry)
  puts entry
end

class String
  
  def undelimit(options={})
    not_urls = options[:not_urls]
    delimiter = (options[:delimiter] ||= /\|/)
    delimiter = Regexp.new(Regexp.escape(delimiter.to_s)) if delimiter.is_a? String
    min_size = (options[:min_size] ||= 4)
    log "Delimiting: #{self} with #{delimiter.to_s}" if YT_LOG_LEVEL == :debug
    #s = CGI.unescape(self.to_s).to_s
    if !not_urls
      parts = CGI.unescape(self).split(delimiter).map(&:strip).compact.select{|st|  st =~ /^http/ }
      log "Delimited Parts were #{parts.inspect}" if YT_LOG_LEVEL == :debug
      return parts.map{|st| st.gsub(/\,[0-9]+$/,'').fetch_as_url(:limit => 10)}
    else
      parts = self.split(delimiter).map(&:strip).compact
      log "Delimited  Parts were #{parts.inspect}" if YT_LOG_LEVEL == :debug
      return parts
    end
  end
  
  def fetch_as_url(options={})
    limit = (options[:limit] ||= 10)
    path = options[:referrer] || self
    path = CGI.unescape(path)
    return false if limit == 0
    url = URI.parse(path)
    ending = [url.path, url.query].join("?")
    params = {}
    params["query"] = Rack::Utils.parse_nested_query(url.query)
    params["url"] = path
    params["path"] = url.path
    params["host"] = url.host
    @h = Host.first_or_create(
      :domain => params["host"],
      :ip     => params["query"]["ip"]
    )
    response = nil
    log "Fetching #{path}"
    Net::HTTP.start(url.host, 80) {|http|
      response = http.head(ending)
      n_headers = response.to_hash
      n_headers["code"] = params["response"] = response.code

      n_headers.each_pair{|k,v| n_headers[k] = v[0] if (v.is_a? Array and v.size == 1)}
      params["headers"] = n_headers
    }
    begin
    @f = Format.first_or_create(
      { :itag    => params["query"]["itag"].to_s},
      {
        :itag    => params["query"]["itag"].to_s,
        :host_id => @h.id.to_i,
        :itag    => params["query"]["itag"].to_s,
        :mime    => params["headers"]["content-type"].to_s
      }
    )
  rescue => e
    log "New format could not be saved to DB: " + e.message
  end
    log params.to_yaml  if YT_LOG_LEVEL == :debug
    case response
      when Net::HTTPSuccess     then return params
      when Net::HTTPRedirection then return fetch_as_url(:referrer => response['location'], :limit => limit - 1)
      else return params
    end
  end
  
end

class Hash
  
  def dup_key(key, hash)
    key.to_a.each do |k|
      if k =~ /_map$/
        self[k.to_sym] = (hash[k] || hash[k.to_sym]).to_s.undelimit #rescue []
      elsif k =~ /_list$/
        self[k.to_sym] = (hash[k] || hash[k.to_sym]).to_s.undelimit(:delimiter => /\//, :not_urls => true ) #rescue []
      else
        self[k.to_sym] = hash[k]# rescue []
      end
      
    end
    return self
  end
  
end

class Array
  
  def map_to(values)
    result = {}
    self.each_with_index do |k,i|
      result[k] = values[i].to_s rescue nil
    end
    return result
  end
  
end

class YouTubeResource
  
  attr_accessor :config, :http_code, :url, :headers, :params, :parent, :title, :id, :length, :user, :video_id, :saved, :path
  
  def initialize(config_hash, parent = nil)
    @parent = parent
    @config = config_hash
    @url = @config["url"]
    @headers = @config["headers"]
    @params = @config["query"]
    @path = nil
    @saved = false
    if @parent
      @user = @parent[:user]
      @title = @parent[:title]
      @video_id = @parent[:video_id]
      @length = @parent[:length]
    else
      @user = @title = @video_id = @length = nil
    end
    log "NEW YOUTUBE RES: #{@config.to_yaml}"  if YT_LOG_LEVEL == :debug
    #fh = `curl -m 7 -s -r 0-2000 \"#{url}\" > tmp.tmp`
    #fh = `mdls tmp.tmp`
    #FileUtils.rm "tmp.tmp"
    #fh = fh.to_s
    #puts fh
    @vs = VideoStream.first_or_create(
      {:video_id  =>  @parent[:video_id].to_s, :format_id => @config["query"]["itag"].to_s},
      { :video_id  =>  @parent[:video_id].to_s,
        :signature  =>  @config["query"]["signature"].to_s,
        :mime =>  @config["headers"]["content-type"].to_s,
        :format_id =>  @config["query"]["itag"].to_s,
        :http_status => config_hash["response"].to_s,
        :params => @params.to_yaml,
        :headers => @headers.to_yaml,
        :content_length => @config["headers"]["content-length"].to_i,
        :url => @url.to_s#,
        #:file_header => fh
        })
  end
  
  def h(name)
    @headers[name.to_s]
  end
  
  def p(name)
    @params[name.to_s]
  end
  
  def size
    h("content-length").to_i
  end
  
  def mime
   h("content-type")
  end
  
  def ext
    mime.split("/").last rescue "flv"
  end
  
  def burst
    p :burst
  end
  
  def factor
    p :factor
  end
  
  def signature
    p :signature
  end
  
  def id
    p :id
  end
  
  def itag
    p :itag
  end
  
  def version
    p :sver
  end
  
  def saved?
    path &&  File.exist?(path) && File.size(path) == size
  end
  
  def filename
    if title || video_id || id
      (title || video_id || id) + "." + ext
    else
      "YouTubeVideo-#{Time.now.to_s}" + "." + ext
    end
  end
  
  def download(location = DEFAULT_DOWNLOAD_LOCATION)
    log "Downloading #{filename}"
    if saved?
      raise "A File with the same filesize exists at #{@path}"
    end
    @destination = File.expand_path(File.join(location, filename))
    @tmp_dest    = @destination + ".part"
    log "Attempting to save to #{@destination}"
    begin
      FileUtils.mkdir_p File.dirname(@destination)
      f = File.open(@tmp_dest, "w+")
      f.puts open(url).read
      f.close
      File.rename(File.expand_path(f.path), @destination)
    rescue => e
      raise "Could not be downloaded to #{@destination} \n\n #{e.message} \n\n #{e.backtrace.join("\n")}"
    end
    @saved = true
    @path = File.expand_path(f.path)
    log "File can be viewed at #{@path}"
    return @path
  end
  
end

class YouTube

  attr_accessor :video_id, :title, :user, :watch_url, :page_content, :basic_config, :full_config, :short_config, :config_text, :fmt, :formats, :scraped_url
  
  FORMATS = %w{5 34 35 18 22 37 38 43 45 17}
  
  
  def self.get_video_id(url)
    url.match(/^[^v]+v.(.{11}).*|^([\w\-]{0,11})$/).to_a.compact.select{|u| u.length <= 12 }.first
  end
  
  def watch_url
    return "http://www.youtube.com/watch?v=#{video_id}&fmt=#{@fmt}"
  end

  def initialize(video_id, fmt=18)
    raise "Video ID was nil" if video_id.nil?
    @video_id = video_id
    @fmt = fmt
    @formats = []
    @short_config = {}
    @basic_config = nil
    @full_config = {}
    @config_text = nil
    scrape
    @title = @nokogiri_page.css("h1")[0].content.strip
    @user = @page_content.match(/VIDEO_USERNAME[^a-zA-Z0-9]+([a-zA-Z0-9\-_]+)/).to_s.split(":").last.gsub(/[\'\"]+/,'').strip
    @v = Video.first_or_create(
      :video_id => @video_id,
      :title    => @title,
      :user     => @user
    )
  end
  
  def scrape
    begin
      @nokogiri_page = Nokogiri::HTML(open(watch_url))
      @page_content  = @nokogiri_page.content
    rescue => e
      raise "Watch url #{@watch_url} could not resolve - #{e.message} \n\n #{e.backtrace.join("\n")}"
    end
  end

  
  def gather_config
    @config_text = @page_content.scan(/var swfConfig \= .*$/).first.gsub(/^[a-zA-Z \=]+|\;$/,'').to_s
    @basic_config ||= Yajl::Parser.new.parse(@config_text)["args"]
    return @basic_config
  end
  
  def parse_stream_list(config_key, add_key)
    parsed = @full_config[:scraped_config][config_key.to_s].split(",").map{|f| f.split("|")}
    @formats << parsed
    return @full_config[add_key] = parsed.to_hash
  end
  
  def parse_config
     @full_config = {}
     @full_config[:scraped_config] = @basic_config
     @full_config[:scraped_url] = watch_url
     @short_config = {:id => @video_id, :title => @title, :user => @user}
     @full_config.dup_key(%w{video_id t sk plid length_seconds keywords fmt_stream_map fmt_url_map fmt_list}, @basic_config)
     @short_config.dup_key(%w{video_id t length_seconds}, @basic_config)
     parse_stream_list(:fmt_stream_map, :stream_formats)
     parse_stream_list(:fmt_url_map, :url_formats)
     @full_config.merge!(@short_config)
     #log @full_config.to_yaml
     return @full_config
  end
  
  
  def all_streams
    return full_config[:fmt_stream_map]
  end
  
  def streams(valid=true)
    return all_streams.map{|str|  YouTubeResource.new(str, self.short_config) }
 end
  
  def stream_urls(valid=true)
   streams(valid).map{|s| s.url}
  end
  
  def retrieve
    scrape
    gather_config
    parse_config
    streams
  end
  
  def self.download(url_or_id)
    video_id = get_video_id(url_or_id)
    yt = YouTube.new(video_id)
    yt.retrieve
    s = yt.streams.first
    return s.download
  end

end

