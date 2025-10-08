require "rails_helper"

RSpec.describe "Bulk categorize", type: :request do
  let!(:user) { create(:user) }
  before { allow(User).to receive(:first).and_return(user) }

  it "applies a category to selected transactions" do
    t1 = create(:transaction, user: user, category: nil)
    t2 = create(:transaction, user: user, category: nil)

    post "/v1/transactions/bulk_update",
      params: { ids: [t1.id, t2.id], category_name: "Shopping" }.to_json,
      headers: { "CONTENT_TYPE" => "application/json" }

    expect(response).to have_http_status(:no_content)
    cat = user.categories.find_by(name: "Shopping")
    expect(t1.reload.category_id).to eq(cat.id)
    expect(t2.reload.category_id).to eq(cat.id)
  end
end