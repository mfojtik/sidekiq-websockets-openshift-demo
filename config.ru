load './server.rb'

ENV['OPENSHIFT_RUBY_IP'] ||= '127.0.0.1'
ENV['OPENSHIFT_RUBY_PORT'] ||= '9292'
ENV['LISTEN_PID'] = 'puma.pid'

Faye::WebSocket.load_adapter('puma')

EM.run {
  $redis =  EM::Hiredis.connect(REDIS_URL)
  events = Puma::Events.new($stdout, $stderr)
  binder = Puma::Binder.new(events)
  binder.parse(["tcp://#{ENV['OPENSHIFT_RUBY_IP']}:#{ENV['OPENSHIFT_RUBY_PORT']}"], App)
  server = Puma::Server.new(App, events)
  server.binder = binder
  server.run
}
