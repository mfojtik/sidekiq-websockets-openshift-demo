require 'bundler/setup'
require 'faye/websocket'
require 'em-hiredis'
require 'rack'

# Gain access to the Sidekiq workers:
#
require_relative './initialize'

static = Rack::File.new(File.join(File.dirname(__FILE__), 'public'))

App = lambda do |env|

  if Faye::WebSocket.websocket?(env)
    @channel = EM::Channel.new

    pubsub = $redis.pubsub

    pubsub.subscribe('demo')

    pubsub.on(:message) do |channel, message|
      puts "Message received: #{message}"
      @channel.push(message)
    end

    ws = Faye::WebSocket.new(env, ['demo'], :ping => 5)

    ws.on :open do |event|
      @sid = @channel.subscribe do |message|
        ws.send(message)
      end
    end

    ws.on :message do |event|
      ws.send(event.data)
    end

    ws.on :close do |event|
      @channel.unsubscribe(@sid)
      ws = nil
    end

    # Return async Rack response
    ws.rack_response

  else
    # Normal HTTP request
    static.call(env)
  end

end

def App.log(message)
  $stdout.puts message
end
