require './models/top.rb'
require 'mongoid'
require 'yajl/json_gem'

#require "sinatra"
require "sinatra/base"

class MyApp < Sinatra::Base
  configure do
     Mongoid.configure do |config|
      @yml = YAML::load(File.open(File.dirname(__FILE__) + '/database.yml'))
      name = @yml['mongo_database']
      host = @yml['mongo_host']
      port = @yml['mongo_port']   
      config.master = Mongo::Connection.new.db(name)
      config.persist_in_safe_mode = false
    end
  end

  before do
    content_type :json
  end


  get '/' do
    "use /top.json"
  end 

  get '/top.json' do

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
      error 404, {:error => "user not found"}.to_json 
    end

  end

end
