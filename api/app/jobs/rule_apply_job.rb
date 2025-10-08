class RuleApplyJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    RuleEngine.new(user).apply!
  end
end
