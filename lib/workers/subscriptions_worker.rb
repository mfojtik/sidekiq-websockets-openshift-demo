class SubscriptionsWorker

  include Sidekiq::Worker

  def perform(token, user)
    sub_arr = JSON::parse(github.get('/users/%s/subscriptions' % user, { :access_token => token }).body)
    sub_arr.each do |repo|
      redis.publish('/users/%s/subscriptions' % user, JSON::dump({"name" => repo['name']}))
      RepoWorker.perform_async(token, user, repo['full_name'])
    end
  end

  private

  def redis
    @redis ||= Redis.new(REDIS_CONF)
    @redis.auth(ENV['REDIS_PASSWORD']) if ENV['REDIS_PASSWORD']
    @redis
  end

  def github
    @client ||= Faraday.new(:url => 'https://api.github.com') do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end
  end

end
