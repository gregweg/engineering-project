FactoryBot.define do
  factory :rule do
    association :user
    field { "description" }           # "description" | "amount"
    operator { "contains" }           # contains | equals | greater_than | less_than
    value { "amazon" }
    action_type { "set_category" }    # set_category | flag
    action_value { "Shopping" }       # category name for set_category
    priority { 0 }
    enabled { true }
  end
end