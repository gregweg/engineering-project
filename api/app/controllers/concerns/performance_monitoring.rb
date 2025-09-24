module PerformanceMonitoring
  extend ActiveSupport::Concern

  included do
    around_action :monitor_performance
  end

  private

  def monitor_performance
    start_time = Time.current
    memory_before = get_memory_usage

    yield

    duration = (Time.current - start_time) * 1000
    memory_after = get_memory_usage
    memory_delta = memory_after - memory_before

    log_performance_metrics(duration, memory_delta)
  end

  def get_memory_usage
    `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
  rescue
    0
  end

  def log_performance_metrics(duration, memory_delta)
    if duration > 1000 || memory_delta > 50 # Log slow requests or high memory usage
      Rails.logger.warn(
        "Performance Warning: #{request.method} #{request.path} " \
        "took #{duration.round(2)}ms, memory delta: #{memory_delta.round(2)}MB"
      )
    end

    # Store metrics in Redis for monitoring
    if defined?($redis)
      key = "perf:#{controller_name}:#{action_name}"
      $redis.lpush(key, {
        timestamp: Time.current.to_i,
        duration: duration.round(2),
        memory_delta: memory_delta.round(2),
        path: request.path
      }.to_json)
      $redis.ltrim(key, 0, 99) # Keep last 100 entries
      $redis.expire(key, 1.day.to_i)
    end
  rescue => e
    Rails.logger.debug("Performance monitoring error: #{e.message}")
  end
end