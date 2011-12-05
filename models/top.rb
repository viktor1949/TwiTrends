require 'mongoid'

class Top
  include Mongoid::Document   
  field :rate, type: Integer
  field :hashtag, type: String
  field :count, type: Integer
end