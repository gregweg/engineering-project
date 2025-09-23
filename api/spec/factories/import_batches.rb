FactoryBot.define do
  factory :import_batch do
    user { nil }
    filename { "MyString" }
    status { "MyString" }
    total_rows { 1 }
    processed_rows { 1 }
    error_messages { "" }
  end
end
