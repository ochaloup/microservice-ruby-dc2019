require 'sinatra/base'
require 'rest-client'

module Microservice
  class Api < Sinatra::Base
    helpers do
      def repo
        Repo.instance
      end

      def lra_header
        request.env['HTTP_LONG_RUNNING_ACTION']
      end

      def enlist_lra
        return unless lra_header
        base_url = request.env['REQUEST_URI'] + 'lra'
        body = <<~EOF
          <#{base_url}/leave>; rel="leave"; title="leave URI"; type="text/plain",<#{base_url}/complete>; rel="complete"; title="complete URI"; type="text/plain",<#{base_url}/compensate>; rel="compensate"; title="compensate URI"; type="text/plain",<#{base_url}/status>; rel="status"; title="status URI"; type="text/plain"
        EOF
      end

      def complete_lra
        lra_resource('close').put '' if lra_header
      end

      def cancel_lra
        lra_resource('cancel').put '' if lra_header
      end

      def lra_resource(path = '')
        RestClient::Resource.new(lra_header)[path]
      end
    end

    post '/async/?' do
      repo.insert(Record.new).to_json
    end

    post '/' do
      enlist_lra
      record = Record.new :state => 'approved', :data => {:lra_header => lra_header }
      repo.insert(record).to_json
    end

    post '/fail/?' do
      enlist_lra
      record = Record.new :state => 'rejected', :data => {:lra_header => lra_header }
      repo.insert(record).to_json
    end

    put '/lra/compensate' do
      Repo.find_lra(lra_header).each do |record|
        record.state = 'revoked'
        Repo.update(record)
      end
    end

    put '/lra/complete' do
      Repo.find_lra(lra_header).each do |record|
        # Do something
      end
    end

    get '/:id/status' do
      repo.find(params['id']).to_json
    end

    post '/:id/complete' do

    end

    post '/:id/compensate' do
      record = repo.find(params['id'])
      record.state = 'revoked'
      repo.update(record).to_json
    end
  end
end
