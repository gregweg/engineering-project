require "rails_helper"

RSpec.describe AnomalyDetector do
  let(:user) { create(:user) }

  it "flags missing metadata (blank description)" do
    t = create(:transaction, user: user, description: " ")
    expect {
      AnomalyDetector.new(user).scan!
    }.to change { t.reload.needs_review }.from(false).to(true)
  end

  it "flags simple duplicate (same date, amount, description)" do
    t1 = create(:transaction, user: user, date: Date.today, amount: 10, description: "Coffee")
    t2 = create(:transaction, user: user, date: t1.date, amount: t1.amount, description: "Coffee")
    expect {
      AnomalyDetector.new(user).scan!
    }.to change { user.transactions.where(needs_review: true).count }.by(1)
     .and change { TransactionAnomaly.count }.by(1)
  end
end