require 'sinatra/base'

module Microservice
  class AdminApi < Sinatra::Base
    def repo
      Repo.instance
    end

    get '/' do
      repo.index.to_json
    end

    get '/:id' do
      record = repo.find(params['id']) || {}
      record.to_json
    end

    post '/:id/reject' do
      record = repo.find(params['id'])
      record.state = 'rejected'
      repo.update(record).to_json
    end

    post '/:id/approve' do
      record = repo.find(params['id'])
      record.state = 'approved'
      repo.update(record).to_json
    end
  end
end
