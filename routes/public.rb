
  get DOMAIN_URL_REGEX do
    @domain = params[:captures].first.to_s
   # puts @domain
    haml :index, :layout => :"templates/main"
  end
  