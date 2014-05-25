###
# Compass
###

# Susy grids in Compass
# First: gem install susy
# require 'susy'

# Change Compass configuration
# compass_config do |config|
#   config.output_style = :compact
# end

###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
# Dir["source/data/*.json"].each do |data|
#   page data, :content_type => 'application/json', :layout => false
# end

#page "/path/to/file.html", :layout => false
#
# With alternative layout
# page "/path/to/file.html", :layout => :otherlayout
#
# A path which all have the same layout
# with_layout :admin do
#   page "/admin/*"
# end

# Proxy (fake) files
#page "/counties", :proxy => "/index.html.erb", :content_type => 'text/html'
proxy '/counties.html', '/index.html'
proxy '/recruits.html', '/index.html'
###
# Helpers
###

# Automatic image dimensions on image_tag helper
# activate :automatic_image_sizes

# Methods defined in the helpers block are available in templates
helpers do
  require 'csv'
  require 'json'

  def schools
    @schools ||= CSV.parse(File.read('source/data/schools.csv'), :headers => true)
  end

  def recruits
    @recruits ||= CSV.parse(File.read('source/data/recruits.csv'), :headers => true)
  end

  def places
    @places ||= CSV.parse(File.read('source/data/places.csv'), :headers => true)
  end

  def counties
    @counties ||= JSON.parse(File.read('source/data/counties.json'))
  end

  def years
    (2002..2013).to_a.reverse
  end

end

set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'images'

# Build-specific configuration
configure :build do
  # For example, change the Compass output style for deployment
  # activate :minify_css

  # Minify Javascript on build
  # activate :minify_javascript

  # Enable cache buster
  # activate :cache_buster

  # Use relative URLs
  activate :relative_assets

  # Compress PNGs after build
  # First: gem install middleman-smusher
  # require "middleman-smusher"
  # activate :smusher

  # Or use a different image path
  # set :http_path, "/Content/images/"
end

# To deploy to a remote branch via git (e.g. gh-pages on github):
activate :deploy do |deploy|
  deploy.build_before = true
  deploy.method = :git
end

ignore '**/*/README*'
ignore '**/*/LICENSE'
ignore '**/*/CONTRIBUTING*'
