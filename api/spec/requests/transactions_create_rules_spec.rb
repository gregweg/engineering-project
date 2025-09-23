require "rails_helper"

RSpec.describe "Rule auto-apply", type: :request do
  let!(:user) { create(:user) }
  before { allow(User).to receive(:first).and_return(user) }

  it "categorizes Amazon via description rule" do
    create(:rule, user: user, field: "description", operator: "contains",
           value: "amazon", action_type: "set_category", action_value: "Shopping")
    post "/v1/transactions",
      params: { transaction: { date: "2025-09-01", description: "AMAZON order 1", amount: "12.00" } }.to_json,
      headers: { "CONTENT_TYPE" => "application/json" }
    expect(response).to have_http_status(:created)
    t = Transaction.last
    expect(user.categories.find_by(name: "Shopping").id).to eq(t.category_id)
  end
end