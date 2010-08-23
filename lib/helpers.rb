  helpers do
    def youtube(post)
       haml "%div.post\n  %a{:href=>post.url}\n    %img{:src => post.thumbnail}"
    end
  end
