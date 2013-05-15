require 'rubygems'
require 'sinatra'
require 'haml'
require 'coffee-script'

require 'json'

# Helpers
require './lib/render_partial'

enable :logging
                               # Set Sinatra variables
set :app_file, __FILE__
set :root, File.dirname(__FILE__)
set :views, 'views'
set :public_folder, 'public'
set :haml, {:format => :html5} # default Haml format is :xhtml

@@mtgox    = {:USD => false, :GBP => false, :CHF => false, :EUR => false}
@@bitstamp = {:high => false, :low => false}
@@btc_e    = {:USD => false, :EUR => false}

# Application routes
get '/' do
  haml :index, :layout => :'layouts/application'
end

get '/about' do
  haml :about, :layout => :'layouts/page'
end

get '/mtgox/:currency.json' do
  if @@mtgox.keys.include? params[:currency].to_sym
    headers({'Content-Type' => 'application/x-json'})
    body({:rate => @@mtgox[params[:currency].to_sym]}.to_json)
  else
    halt 404
  end
end

get '/btc_e/:currency.json' do
  if @@btc_e.keys.include? params[:currency].to_sym
    headers({'Content-Type' => 'application/x-json'})
    body({:rate => @@btc_e[params[:currency].to_sym]}.to_json)
  else
    halt 404
  end
end

get '/bitstamp.json' do
  headers 'Content-Type' => 'application/x-json'
  body @@bitstamp.to_json
end

require 'net/https'
require 'pp'

def update_mtgox
  @@mtgox.keys.each do |k|
    p "MtGox: Updating #{k} ticker..."
    uri = URI("https://data.mtgox.com/api/1/BTC#{k}/ticker")
    h = Net::HTTP.new uri.host, uri.port
    h.use_ssl = true
    resp = h.get uri.request_uri
    res  = JSON.parse resp.body
    if res['result'] == 'success'
      @@mtgox[k] = res['return']['avg']['value']
      #logger.info('MtGox') { "Successfully updated #{k} ticker!" }
    end
  end
end

def update_bitstamp
  p 'BitStamp: Updating ticker...'
  uri = URI('https://www.bitstamp.net/api/ticker/')
  h = Net::HTTP.new uri.host, uri.port
  h.use_ssl = true
  resp = h.get uri.request_uri
  res       = JSON.parse resp.body
  @@bitstamp = {:high => res['high'], :low => res['low']}
end

def update_btce
  @@btc_e.keys.each do |k|
    p "BTC-E: Updating #{k} ticker..."
    uri = URI("https://btc-e.com/api/2/btc_#{k.to_s.downcase}/ticker")
    h = Net::HTTP.new uri.host, uri.port
    h.use_ssl = true
    resp = h.get uri.request_uri
    res  = JSON.parse resp.body
    @@btc_e[k] = res['ticker']['avg']
  end
  pp @@btc_e
end

def run_then_threadify
  yield

  Thread.new do
    while true
      sleep 1
      yield
    end
  end
end

%w(mtgox bitstamp btce).map do |p|
  run_then_threadify(&method(:"update_#{p}"))
end
