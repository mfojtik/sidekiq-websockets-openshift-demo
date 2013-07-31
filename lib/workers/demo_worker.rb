class DemoWorker

  include Sidekiq::Worker

  # Replace this with some real task...
  #
  def perform
    redis.publish('demo', Time.now.to_s)
    sleep(5)
    self.class.perform_in(5)
  end

  def redis
    redis = Redis.new(REDIS_CONF)
    redis.auth(ENV['REDIS_PASSWORD']) if ENV['REDIS_PASSWORD']
    redis
  end

end
