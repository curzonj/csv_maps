require 'rubygems'
require 'sinatra'
require 'haml'
require 'builder'
require 'csv_map'
require 'logger'
require 'rack_hoptoad'

LOG = Logger.new(ENV['RACK_ENV'] == 'production' ?
  (File.dirname(__FILE__) + '/log/sinatra.log') : $stderr)

%w{ hoptoad_key redirect_url yahoo_key }.each do |key|
  raise "Missing environment variable: #{key}" unless ENV.include?(key)
end

use Rack::HoptoadNotifier, ENV['hoptoad_key']
Yahoo.apikey = ENV['yahoo_key']

# Upload the files
get '/' do
  haml :upload
end

post '/' do
  map = CsvMap.new(params[:map])

  if map.import
    redirect(ENV['redirect_url'] + map.slug)
  else
    @error_msg = "We were unable to load your map, sorry."
    haml :upload
  end
end

# Get the map for google maps
get '/:key' do
  if (@csv_map = CsvMap.get(params['key'])).nil?
    @error_msg = "That map doesn't exist, sorry"
    throw :halt, [404, haml(:upload)]
  end

  content_type 'application/xml', :charset => 'utf-8'
  builder :rss
end
