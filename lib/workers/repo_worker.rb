class RepoWorker

  include Sidekiq::Worker

  sidekiq_options :retry => false

  def perform(token, user, repo_name)
    repo = github.get('/repos/%s' % repo_name, { :access_token => token}).body
    redis.publish('/users/%s/repos' % user, repo)
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
