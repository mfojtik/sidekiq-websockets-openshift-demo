require 'bundler/setup'
require 'faye/websocket'
require 'rack'

# Gain access to the Sidekiq workers:
#
require_relative './initialize'

GITHUB_QUEUES = ['subscriptions', 'repos']

App = lambda do |env|

  if Faye::WebSocket.websocket?(env)

    @channel = EM::Channel.new
    params = Rack::Request.new(env).params

    redis = $redis.connect.dup

    GITHUB_QUEUES.map { |q| redis.pubsub.subscribe('/users/%s/%s' % [params['user'], q]) }

    redis.pubsub.on(:message) do |channel, message|
      @channel.push(JSON::dump({'c' => channel, 'm' => JSON::parse(message)}))
    end

    ws = Faye::WebSocket.new(env)

    ws.on :open do |event|
      SubscriptionsWorker.perform_async(params['token'], params['user'])
      @sid = @channel.subscribe do |message|
        ws.send(message)
      end
    end

    ws.on :message do |event|
      ws.send(event.data)
    end

    ws.on :close do |event|
      GITHUB_QUEUES.map { |q| redis.pubsub.unsubscribe('/users/%s/%s' % [params['user'], q]) }
      @channel.unsubscribe(@sid)
      ws = nil
    end

    # Return async Rack response
    ws.rack_response

  else
    [301, {"Location" => '/user'}, []]
  end

end

def App.log(message)
  $stdout.puts message
end
