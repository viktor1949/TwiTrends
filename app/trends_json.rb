# encoding: utf-8

require_relative 'models/top.rb'
require 'mongoid'
require 'haml'
require 'yajl/json_gem'
require 'uri'

require "sinatra/base"
require "sinatra/reloader"
require 'rack/mobile-detect'

require 'coffee-script'




class MyApp < Sinatra::Base
  use Rack::MobileDetect

  set :haml, {:format => :html5 }
  #enable :sessions
  
  configure :development do
    register Sinatra::Reloader
  end

  configure do
     Mongoid.configure do |config|
      @yml = YAML::load(File.open(File.expand_path("../database.yml", File.dirname(__FILE__))))

      name = @yml['mongo_database']
      host = @yml['mongo_host']
      port = @yml['mongo_port']   
      config.master = Mongo::Connection.new.db(name)
      config.persist_in_safe_mode = false
    end
  end

  before do
    cache_control :public, :must_revalidate, :max_age => 60
  end

   helpers do
    def escapeURI(link)
      URI.escape(link)
    end

    def request_from_mobile_agent?
      !!env[Rack::MobileDetect::X_HEADER]
    end

  end



  get "/index.js" do
    coffee :ajax
  end


  get '/' do
    @hash_top = Top10.exist_hashs()    
    haml :index 

    #if request_from_mobile_agent?
    #  haml :mobile
    #else
    #  haml :index 
    #end
  end 


  get '/mobile' do
    @hash_top = table.exist_hashs()
    #haml :mobile
    haml :index 
  end 



  get '/about' do  
    haml :about  
  end  

  get '/top.json' do
    mode = params[:mode]

    content_type :json

    table = case mode
       when '10min' then Top10
       when '30min' then Top30
       when 'hour' then Top60
       when 'day' then Top1440
       else Top10
    end

    hash_top = table.exist_hashs()

    if hash_top
        hash_top.map { |item|  
          {
            :hashtag => item.hashtag, 
            :count => item.count,
            :diff => item.diff
          } 
        }.to_json 
    else
      error 404, {:error => "trends info not found"}.to_json 
    end

  end
 
 run! if app_file == $0

end
