# encoding: utf-8
require 'tweetstream'
require 'yaml'
require 'yajl'
require 'mongo'         


MONGO_POOL_SIZE = 100
def init
  @yml = YAML::load(File.open(File.expand_path("../database.yml", File.dirname(__FILE__))))
  db = Mongo::Connection.new(@yml['mongo_host'], @yml['mongo_port'], :pool_size => MONGO_POOL_SIZE).db(@yml['mongo_database'])
  @h_timeline = db.collection("hashtags_timeline") 
  @h_top = db.collection("tops")   
end

def start


  map = <<-eos
    function() {
    now = new Date();
    d = Date.UTC(now.getFullYear(), now.getMonth(), now.getDate(), now.getHours(), now.getMinutes(), now.getSeconds());
    ten_minute_ago = ((d + (new Date).getTimezoneOffset() * 60000) - 600000) /1000
    if (this.created_at > ten_minute_ago){                                   
      emit({hashtag: this.hashtag}, {count: 1});
    }
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
  return if top.count == 0  #if no new data aviable 

  @h_top.remove() #clean htop table

  top.to_a.each_with_index do |r,  index|
    puts "#{r['_id']['hashtag']} --> #{r['value']['count']}"
    @h_top.insert({:rate =>index, :hashtag => r['_id']['hashtag'], :count => r['value']['count']})
  end

  @h_timeline.remove({:created_at => {"$lte" => Time.now.utc.to_i - 3600}})

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

