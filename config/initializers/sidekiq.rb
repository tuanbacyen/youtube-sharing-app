# Be sure to restart your server when you modify this file.

# Configure Sidekiq to use Redis
# Redis is used for background jobs (Sidekiq) and WebSockets (ActionCable)

Sidekiq.configure_server do |config|
  # Configures Sidekiq to use Redis as the message broker
  # Reads from REDIS_URL environment variable or defaults to localhost:6379/0
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end

Sidekiq.configure_client do |config|
  # Configures Sidekiq client to use Redis
  # Reads from REDIS_URL environment variable or defaults to localhost:6379/0
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end
