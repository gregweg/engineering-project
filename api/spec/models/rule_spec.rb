require "rails_helper"

RSpec.describe Rule, type: :model do
  it "validates allowed fields/operators/actions" do
    r = build(:rule, field: "description", operator: "contains", action_type: "set_category")
    expect(r).to be_valid

    expect(build(:rule, field: "bad")).not_to be_valid
    expect(build(:rule, operator: "bad")).not_to be_valid
    expect(build(:rule, action_type: "bad")).not_to be_valid
  end
end