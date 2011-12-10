# encoding: utf-8

require './models/top.rb'
require 'mongoid'
require 'haml'
require 'yajl/json_gem'
require 'uri'

require "sinatra/base"
require 'rack/mobile-detect'


class MyApp < Sinatra::Base
  use Rack::MobileDetect, :redirect_to => '/mobile'

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
  end


  get '/' do
    @hash_top = Top.all.asc(:rate)
    haml :index 
  end 

  get '/mobile' do
    @hash_top = Top.all.asc(:rate)
    haml :mobile
  end 



  get '/about' do  
    haml :about  
  end  

  get '/top.json' do

    content_type :json
    hash_top = Top.all.asc(:rate)

    if hash_top
        hash_top.map { |item|  
          {
            :rate => item.rate,
            :hashtag => item.hashtag, 
            :count => item.count
          } 
        }.to_json 
    else
      error 404, {:error => "trends info not found"}.to_json 
    end

  end
 
 run! if app_file == $0

end
