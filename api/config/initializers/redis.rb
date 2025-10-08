# config/initializers/redis.rb
redis_url = ENV.fetch("REDIS_URL") do
  Rails.env.development? ? "redis://127.0.0.1:6379/0" : "redis://redis:6379/0"
end

$redis = Redis.new(url: redis_url)

# Configure Rails cache store
Rails.application.configure do
  config.cache_store = :redis_cache_store, {
    url: redis_url,
    connect_timeout: 30,
    read_timeout: 0.2,
    write_timeout: 0.2,
    reconnect_attempts: 1,
    error_handler: -> (method:, returning:, exception:) {
      Rails.logger.warn("Redis error: #{method} - #{exception.class}: #{exception.message}")
    }
  }
end