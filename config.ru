if File.exist? '.env'
  require 'dotenv'
  Dotenv.load
end

require 'sinatra/cyclist'
require 'dashing'

configure do
  set :auth_token, ENV['DASHING_AUTH_TOKEN']
  set :routes_to_cycle_through, [
    :google_analytics
  ]
  set :cycle_duration, 60
  set :default_dashboard, '_cycle'

  helpers do
    def protected!
      return if authorized?
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      throw(:halt, [401, "Not authorized\n"])
    end

    def authorized?
      return true if ENV['BASIC_AUTH_USERNAME'].nil? || ENV['BASIC_AUTH_PASSWORD'].nil?
      @auth ||= Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [ENV['BASIC_AUTH_USERNAME'], ENV['BASIC_AUTH_PASSWORD']]
    end
  end
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application
