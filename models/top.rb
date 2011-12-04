require 'mongoid'

class Top
  include Mongoid::Document
  field :hashtag, type: String
  field :count, type: Integer
end