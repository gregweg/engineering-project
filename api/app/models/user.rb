class User < ApplicationRecord
  has_many :transactions, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :rules, dependent: :destroy
  has_many :import_batches, dependent: :destroy
end
