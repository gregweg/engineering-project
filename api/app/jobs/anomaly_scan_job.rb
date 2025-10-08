class AnomalyScanJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    AnomalyDetector.new(user).scan!
  end
end
