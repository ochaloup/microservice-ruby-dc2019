require 'multi_json'

module Microservice
  class Record
    attr_accessor :id, :state, :data

    def initialize(id: nil, state: 'pending', data: {})
      @id = id
      @state = state
      @data = data
    end

    def to_json(_json_generator_state = nil)
      MultiJson.dump(:id => id, :state => state, :data => data)
    end
  end
end
