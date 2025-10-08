require "rails_helper"

RSpec.describe "Transactions API", type: :request do
  let!(:user) { create(:user) }

  # If your controller uses current_user, stub it or switch to the demo user:
  before do
    allow(User).to receive(:first).and_return(user)
  end

  it "creates a transaction" do
    payload = {
      transaction: {
        date: "2025-09-01",
        description: "Amazon order 1234",
        amount: "49.99"
      }
    }

    expect {
      post "/v1/transactions", params: payload.to_json, headers: { "CONTENT_TYPE" => "application/json" }
    }.to change { Transaction.count }.by(1)

    expect(response).to have_http_status(:created)
    body = JSON.parse(response.body)
    expect(body["description"]).to eq("Amazon order 1234")
  end

  it "rejects bad date format" do
    payload = { transaction: { date: "09/01/2025", description: "Bad date", amount: "10.00" } }
    post "/v1/transactions", params: payload.to_json, headers: { "CONTENT_TYPE" => "application/json" }
    expect(response.status).to eq(422)
    expect(JSON.parse(response.body)["error"]).to match(/Invalid date/i)
  end

  it "lists transactions" do
    create(:transaction, user: user)
    get "/v1/transactions", params: { limit: 1 }
    expect(response).to have_http_status(:ok)
    list = JSON.parse(response.body)
    expect(list.length).to eq(1)
  end
end