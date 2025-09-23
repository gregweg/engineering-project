require "rails_helper"

RSpec.describe RuleApplyJob, type: :job do
  it "runs the rule engine for the user" do
    user = create(:user)
    expect_any_instance_of(RuleEngine).to receive(:apply!)
    described_class.perform_now(user.id) # ActiveJob
  end
end