require 'microservice'

rack = Rack::Builder.app do
  run Rack::URLMap.new('/'      => Sinatra.new(Microservice::Api),
                       '/admin' => Sinatra.new(Microservice::AdminApi))
end
Rack::Server.new(:app => rack, :Port => 4567, :Host => '0.0.0.0').start
