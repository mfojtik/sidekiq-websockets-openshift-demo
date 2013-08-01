require 'sinatra/base'
require 'pry'

CLIENT_ID = ''
CLIENT_SECRET = ''

class Router < Sinatra::Base

  enable :sessions

  get '/' do
    "Usage: /user/GITHUB_USER"
  end

  get '/callback' do
    session_code = request.env['rack.request.query_hash']["code"]
    client = Faraday.new(:url => 'https://github.com') do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end
    response = client.post do |r|
      r.url  '/login/oauth/access_token'
      r.params = {
        :client_id => CLIENT_ID,
        :client_secret => CLIENT_SECRET,
        :code => session_code
      }
      r.headers['Accept'] = 'application/json'
    end
    session[:access_token] = JSON.parse(response.body)["access_token"]
    redirect '/user/%s' % session[:current_user]
  end

  get '/:user' do
    if session[:access_token]
      erb :user
    else
      session[:current_user] = params[:user]
      redirect 'https://github.com/login/oauth/authorize?client_id=%s' % CLIENT_ID
    end
  end

end
