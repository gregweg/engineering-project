require "rails_helper"

RSpec.describe TxnUtils do
  it "normalizes description and fingerprints consistently" do
    fp1 = described_class.fingerprint(user_id: 1, date: Date.new(2025,9,1), amount: 10, description: "  Amazon  ")
    fp2 = described_class.fingerprint(user_id: 1, date: Date.new(2025,9,1), amount: 10, description: "amazon")
    expect(fp1).to eq(fp2)
  end
end