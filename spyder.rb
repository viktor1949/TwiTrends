# encoding: utf-8
require 'tweetstream'
require 'yaml'
require 'yajl'
require 'time'
require 'unicode'         
require 'mongo'         


MONGO_POOL_SIZE = 100

def start
    

  @yml = YAML::load(File.open(File.dirname(__FILE__) + '/database.yml'))
  db = Mongo::Connection.new(@yml['mongo_host'], @yml['mongo_port'], :pool_size => MONGO_POOL_SIZE).db(@yml['mongo_database'])
  @tweets = db.collection("tweets") 
  @h_timeline = db.collection("hashtags_timeline") 
  @hastags = db.collection("hashtags_top") 
    
  TweetStream.configure do |config|
    config.username = @yml['twi_user']
    config.password = @yml['twi_passwd']
    config.auth_method = :basic
    config.parser   = :yajl
  end  

  stream = TweetStream::Client.new
  q = "и,в,не,на,я,быть,он,с,что,а,по,это,она,этот,к,но,они,мы,как,из,у,который,то,за,свой,что,весь,год,от,так,о,для,ты,же,все,тот,мочь,вы,человек,такой,его,сказать,только,или,еще,бы,себя,один,как,уже,до,время,если,сам,когда,другой,вот,говорить,наш,мой,знать,стать,при,чтобы,дело,жизнь,кто,первый,очень,два,день,ее,новый,рука,даже,во,со,раз,где,там,под,можно,ну,какой,после,их,работа,без,самый,потом,надо,хотеть,ли,слово,идти,большой,должен,место,иметь,ничто,то,сейчас,тут,лицо,каждый,друг,нет,теперь,ни,глаз,тоже,тогда,видеть,вопрос,через,да,здесь,дом,да,потому,сторона,какой-то,думать,сделать,страна,жить,чем,мир,об,блять,хуй,пиздец,пизда,охуеть,блядь,бля,ебать,ебаный,член,мудак"

  TweetStream::Client.new.track(q,
    :delete => Proc.new{ |status_id, user_id| puts status_id },
    :limit => Proc.new{ |skip_count|  puts skip_count }
  ) do |status|
    begin         
      next if status.source['twitterfeed'] # no need bot messages from twitterfeed
      #TODO
      #avoid twitter bots. if < 10 followers 
      # reg date: < 1 week
      # statuses > 10
      # and smthng

      status.text.scan(/#\p{Word}+/).each do |hashtag|
        @h_timeline.insert({:hashtag => hashtag, :created_at => Time.now.utc.to_i})

        puts "http://twitter.com/#{status.user.screen_name}/status/#{status.id} -> #{status.text} --> #{hashtag}"        
        @hastags.update({:hashtag => hashtag}, {'$inc' => {:count => 1 }}, :upsert => true )    
      end
      
    rescue => e 
      puts "Error happens #{e.message} \n #{status.text}"
      sleep 3
    end

  end
  
  return
  
  
end

loop do
  begin
    start
  rescue => e
    puts "Shit happens: #{e.message}"
  ensure
    sleep 60
  end


end