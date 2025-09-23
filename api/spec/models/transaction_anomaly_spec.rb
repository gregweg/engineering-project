require "rails_helper"

RSpec.describe TransactionAnomaly, type: :model do
  it "belongs to txn" do
    anomaly = build(:transaction_anomaly)
    expect(anomaly.txn).to be_a(Transaction)
  end
end