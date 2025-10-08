FactoryBot.define do
  factory :transaction do
    association :user
    category { nil } # category is optional
    date { Date.today }
    amount { BigDecimal("12.34") }
    description { "Test purchase" }
    metadata { {} }
    fingerprint { SecureRandom.hex(16) }
    needs_review { false }
  end
end