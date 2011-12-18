require 'mongoid'

class Top10
  include Mongoid::Document   
  field :hashtag, type: String
  field :count, type: Integer

  class << self

    def exist_hashs
      where(:count.gt => 0).desc(:count).limit(15)
    end

  end

end


class Top30
  include Mongoid::Document   
  field :hashtag, type: String
  field :count, type: Integer

  class << self

    def exist_hashs
      where(:count.gt => 0).desc(:count).limit(15)
    end

  end

end


class Top60
  include Mongoid::Document   
  field :hashtag, type: String
  field :count, type: Integer

  class << self

    def exist_hashs
      where(:count.gt => 0).desc(:count).limit(15)
    end

  end

end


class Top1440
  include Mongoid::Document   
  field :hashtag, type: String
  field :count, type: Integer

  class << self

    def exist_hashs
      where(:count.gt => 0).desc(:count).limit(15)
    end

  end

end
