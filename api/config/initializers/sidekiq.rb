# config/initializers/sidekiq.rb
url = ENV.fetch("REDIS_URL") do
  Rails.env.development? ? "redis://127.0.0.1:6379/0" : "redis://redis:6379/0"
end

Sidekiq.configure_server { |c| c.redis = { url: url } }
Sidekiq.configure_client { |c| c.redis = { url: url } }