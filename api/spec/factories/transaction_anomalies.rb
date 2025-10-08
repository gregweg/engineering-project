FactoryBot.define do
  factory :transaction_anomaly do
    association :txn, factory: :transaction
    flag_type { "duplicate" }
    details { {} }
    resolved { false }
  end
end