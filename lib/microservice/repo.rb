require 'singleton'

module Microservice
  class Repo
    include Singleton

    def initialize
      @records = {}
      @next_id = 0
    end

    def insert(thing)
      thing.id = @next_id
      @next_id += 1
      @records.merge!(thing.id => thing)
      thing
    end

    def find(id)
      id = id.to_i if id.is_a? String
      @records[id]
    end

    def update(thing)
      @records.merge(thing.id => thing)
      thing
    end

    def index
      @records.values
    end
  end
end
