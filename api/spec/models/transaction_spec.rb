require "rails_helper"

RSpec.describe Transaction, type: :model do
  it "is valid with minimal fields" do
    t = build(:transaction)
    expect(t).to be_valid
  end

  it "requires date and amount" do
    t = build(:transaction, date: nil)
    expect(t).not_to be_valid
    t = build(:transaction, amount: nil)
    expect(t).not_to be_valid
  end

  it "supports optional category" do
    t = build(:transaction, category: nil)
    expect(t).to be_valid
  end
end