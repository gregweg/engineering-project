require "rails_helper"

RSpec.describe "Transaction flags", type: :request do
  let!(:user) { create(:user) }
  before { allow(User).to receive(:first).and_return(user) }

  it "flags and unflags a transaction" do
    t = create(:transaction, user: user, needs_review: false)
    patch "/v1/transactions/#{t.id}/flag"
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to eq({ "id" => t.id, "needs_review" => true })
    expect(t.reload.needs_review).to be true

    patch "/v1/transactions/#{t.id}/unflag"
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to eq({ "id" => t.id, "needs_review" => false })
    expect(t.reload.needs_review).to be false
  end

  it "bulk unflags" do
    t1 = create(:transaction, user: user, needs_review: true)
    t2 = create(:transaction, user: user, needs_review: true)
    post "/v1/transactions/bulk_unflag",
      params: { ids: [t1.id, t2.id] }.to_json,
      headers: { "CONTENT_TYPE" => "application/json" }
    expect(response).to have_http_status(:no_content)
    expect([t1.reload.needs_review, t2.reload.needs_review]).to eq([false, false])
  end
end
