require 'dynflow'

class ExampleHelper
  class << self
    def world
      @world ||= create_world
    end

    def create_world
      config = Dynflow::Config.new
      # config.persistence_adapter = persistence_adapter
      config.logger_adapter      = Dynflow::LoggerAdapters::Simple.new $stderr, 1
      config.auto_rescue         = true
      Dynflow::World.new(config).tap do |world|
        puts "World #{world.id} started..."
      end
    end

    def run_web_console(world = ExampleHelper.world)
      require 'dynflow/web'
      dynflow_console = Dynflow::Web.setup do
        set :world, world
      end
      Rack::Server.new(:app => dynflow_console, :Port => 3000).start
    end
  end
end
