FactoryBot.define do
  factory :category do
    association :user
    name  { "General" }
    color { "#888888" }
  end
end