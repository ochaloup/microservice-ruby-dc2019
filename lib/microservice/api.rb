require 'sinatra/base'

module Microservice
  class Api < Sinatra::Base
    def repo
      Repo.instance
    end

    post '/' do
      repo.insert(Record.new).to_json
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
