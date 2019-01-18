require_relative './example_helper.rb'
require 'rest-client'

URL = 'http://localhost:4567'

module Actions
  class EntryAction < ::Dynflow::Action
    def report(message)
      action_logger.info "#{input[:id]}: #{message}"
    end
  end

  class AsyncMicroservice < EntryAction
    include ::Dynflow::Action::Polling
    include ::Dynflow::Action::Revertible

    def invoke_external_task
      report "Invoking external task at #{input[:url]}"
      MultiJson.load(resource.post(''))
    end

    def done?
      external_task['state'] != 'pending'
    end

    def poll_external_task
      report 'Polling external task state'
      MultiJson.load(resource("#{external_task['id']}/status").get)
    end

    def on_finish
      if external_task['state'] == 'rejected'
        error! "#{input[:id]}: The external task failed"
      end
      report 'Finished successfully'
    end

    def revert(parent_action)
      # Call compensate if we actually created a task on the remote side
      if parent_action.run_step.state != :pending
        id = parent_action.output['task']['id']
        plan_action CompensateAsyncMicroservice, :url => parent_action.input[:url],
                                                 :remote_id => id,
                                                 :id => parent_action.input[:id]
      end
      # Either way, mark the step as reverted
      revert_self(parent_action)
    end

    def resource(path = '/')
      @resource ||= RestClient::Resource.new(input[:url])
      @resource[path]
    end

    def poll_intervals
      [1, 5, 10]
    end
  end

  class CompensateAsyncMicroservice < EntryAction
    def run
      report "Reverting"
      RestClient::Resource.new(input[:url])["#{input[:remote_id]}/compensate"].post ''
    end
  end

  class ManyMicroservices < ::Dynflow::Action
    include ::Dynflow::Action::Revertible

    def plan(count)
      concurrence do
        count.times do |i|
          plan_action AsyncMicroservice, :url => URL, :id => i
        end
      end
    end
  end

  class SyncMicroservice < ::Dynflow::Action
    include ::Dynflow::Action::Revertible

    def run
      action_logger.info "GET #{input[:url]}"
      output[:result] = MultiJson.load(RestClient.get(input[:url]))
      action_logger.info "200 #{input[:url]}"
    rescue => e
      error! "#{e.http_code} #{input[:url]}"
    end

    def revert_run
      action_logger.info "Reverting for #{original_input[:url]}"
    end
  end

  class ManySyncMicroservices < ::Dynflow::Action
    include ::Dynflow::Action::Revertible
    def plan
      plan_action SyncMicroservice,
        :url => 'https://jsonplaceholder.typicode.com/users'
      plan_action SyncMicroservice,
        :url => 'https://jsonplaceholder.typicode.com/albums'
      plan_action SyncMicroservice,
        :url => 'https://lobste.rs/foobar'
      plan_action SyncMicroservice,
        :url => 'https://jsonplaceholder.typicode.com/posts'
    end
  end
end

Thread.new do
  sleep 1
  # ExampleHelper.world.trigger ::Actions::ManySyncMicroservices
  ExampleHelper.world.trigger ::Actions::ManyMicroservices, 5
end
ExampleHelper.run_web_console
