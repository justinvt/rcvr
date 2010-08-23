require 'sass'

  get '/style.css' do
    content_type 'text/css', :charset => 'utf-8'
    sass :"css/style.css", :style => :expanded # overridden
  end
