require "rails_helper"

RSpec.describe RuleEngine do
  let(:user) { create(:user) }

  it "categorizes transactions whose description contains a value" do
    create(:transaction, user: user, description: "Amazon order 1234", category: nil)
    create(:rule, user: user, field: "description", operator: "contains", value: "amazon",
                  action_type: "set_category", action_value: "Shopping", priority: 0)

    expect {
      RuleEngine.new(user).apply!
    }.to change { user.transactions.where.not(category_id: nil).count }.by(1)

    cat = user.categories.find_by(name: "Shopping")
    expect(cat).to be_present
  end

  it "flags transactions with amount > threshold using rule" do
    create(:transaction, user: user, amount: 1500, description: "Big TV")
    create(:rule, user: user, field: "amount", operator: "greater_than", value: "1000",
                  action_type: "flag", action_value: "", priority: 1)

    expect {
      RuleEngine.new(user).apply!
    }.to change { user.transactions.where(needs_review: true).count }.by(1)
  end
end