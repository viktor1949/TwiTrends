# encoding: utf-8
require 'tweetstream'
require 'yaml'
require 'yajl'
require 'mongo'         

require 'active_support/all'

#http://stackoverflow.com/questions/2030336/how-do-i-create-a-hash-in-ruby-that-compares-strings-ignoring-case
class CaseInsensitiveHash < HashWithIndifferentAccess
  # This method shouldn't need an override, but my tests say otherwise.
  def [](key)
    super convert_key(key)
  end

  protected
  #TODO add translit
  def convert_key(key)
    key.respond_to?(:downcase) ? key.downcase : key
  end  
end




MONGO_POOL_SIZE = 100
def init
  @yml = YAML::load(File.open(File.expand_path("../database.yml", File.dirname(__FILE__))))
  db = Mongo::Connection.new(@yml['mongo_host'], @yml['mongo_port'], :pool_size => MONGO_POOL_SIZE).db(@yml['mongo_database'])
  @h_timeline = db.collection("hashtags_timeline") 
  @h_top = db.collection("tops")   
  @h_all = db.collection("all")   
  @h_top10 = db.collection("top10s")
  @h_top30 = db.collection("top30s")   
  @h_top60 = db.collection("top60s")   
  @h_top1440 = db.collection("top1440s")   
end

def update_top(table, key, count)
   table.update({:hashtag => key}, 
                    {'$inc' => {:count => count }}, 
                    :upsert => true 
                  )    
end

def remove_old(table, mode=:h10)

  seconds = {
              :h10 => 60 * 10,
              :h30 => 60 * 30,
              :h60 => 60 * 60,
              :h1440 =>  24 * 60 * 60
            }
  
  #find all < n minute
  h_item  = @h_all.find({'$or' => [:time => {"$lte" => Time.now.utc.to_i - seconds[mode]}, mode.to_s => 0 ]})
  h_item.each do |h|

    h['top'].each_key do |key|
      puts "for #{key} minus #{h['top'][key]}"
      # - count of previous value
      table.update({:hashtag => key}, {'$inc' => {:count => h['top'][key] * -1}})          
    end

    #set already checked
    @h_all.update({:time => h['time']}, {'$set' => { mode => 1 }})

  end
  
  #set count = 0 if count < 0 
  table.update({:count => {'$lt' => 0}}, {'$set' => {:count => 0}}, :upsert => false , :multi => true)          

end

def start

  map = <<-eos
    function() {
      emit({hashtag: this.hashtag}, {count: 1});
    }
  eos
  
  reduce = <<-eos
    function(key, values) {
    var count = 0;

    values.forEach(function(v) {
      count += v['count'];
    });

    return {count: count};
  }
  eos
  
  @results = @h_timeline.map_reduce(map, reduce, :out => "mr_results")
  top = @results.find({},:sort => ['value', :desc ], :limit => 30 )
  #return if top.count == 0  #if no new data aviable 


  hash_sorted = CaseInsensitiveHash.new
  top.to_a.each do |r|
    hashtag = r['_id']['hashtag']
    count = r['value']['count']    

    #avoid duplicate hashtags
    hash_sorted[hashtag] = hash_sorted.has_key?(hashtag) ? hash_sorted[hashtag] + count : count    

  end
  
  @h_all.insert(:time =>Time.now.utc.to_i, 
                :top => hash_sorted, 
                :h10 => 0, 
                :h30 => 0, 
                :h60 => 0, 
                :h1440 => 0
                )




  hash_sorted.each_key do |key|

    puts "#{key} --> #{hash_sorted[key]}"
    update_top(@h_top10, key, hash_sorted[key])
    update_top(@h_top30, key, hash_sorted[key])
    update_top(@h_top60, key, hash_sorted[key])
    update_top(@h_top1440, key, hash_sorted[key])
  
  end

  remove_old(@h_top10, :h10)
  remove_old(@h_top30, :h30)
  remove_old(@h_top60, :h60)
  remove_old(@h_top1440, :h1440)

  #clear timeline for next MapReduce
  @h_timeline.remove()

end



init
loop do

  begin
    start
  rescue =>e
    puts "WTF?! Something happens: #{e.inspect}"
  end 

  puts "sleep 60"
  sleep 60        
end

